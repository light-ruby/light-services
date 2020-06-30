# frozen_string_literal: true

RSpec.describe Light::Services do
  it "has a version number" do
    expect(Light::Services::VERSION).not_to be nil
  end

  describe ".config" do
    let(:boolean_params) { %i[load_errors use_transactions rollback_on_error raise_on_error] }

    it "responds to params" do
      boolean_params.each do |param|
        expect(described_class.config).to respond_to(param)
      end
    end
  end

  describe ".configure" do
    after { Light::Services.config.reset_to_defaults! }

    it "responds to params" do
      expect do
        Light::Services.configure do |config|
          config.load_errors = false
          config.use_transactions = false
          config.rollback_on_error = false
          config.raise_on_error = true
        end
      end.not_to raise_error
    end
  end

  context "with two conditions on the same step" do
    let(:class_code) do
      <<-RUBY
        class TwoConditions < ApplicationService
          step :hello_world, if: :first, unless: :second
        end
      RUBY
    end

    it do
      expect { eval(class_code) }.to raise_error(Light::Services::TwoConditions)
    end
  end

  context "with `before` and `after` at the same time" do
    let(:class_code) do
      <<-RUBY
        class TwoConditions < ApplicationService
          step :hello_world, before: :first, after: :second
        end
      RUBY
    end

    it do
      expect { eval(class_code) }.to raise_error(Light::Services::Error)
    end
  end

  context "with wrong condition type" do
    let(:class_code) do
      <<-RUBY
        class WrongCondition < ApplicationService
          step :hello_world, if: 42

          private
          
          def hello_world
            # Hey, whats up?
          end
        end

        WrongCondition.run
      RUBY
    end

    it do
      expect { eval(class_code) }.to raise_error(Light::Services::Error)
    end
  end

  context "with not existed step" do
    let(:class_code) do
      <<-RUBY
        class NoStep < ApplicationService
          step :hello_world
        end

        NoStep.run
      RUBY
    end

    it do
      expect { eval(class_code) }.to raise_error(Light::Services::NoStepError)
    end
  end

  context "with multiple conditions" do
    let(:service) { WithConditions.run(add_c: true, do_not_add_d: false) }

    it { expect(service.word).to eql("abcd") }
  end

  context "with multiple conditions 2" do
    let(:service) { WithConditions.run }

    it { expect(service.word).to eql("ab") }
  end

  context "with `always: true` step" do
    let(:service) { WithConditions.with(use_transactions: false).run(fake_error: true) }

    it { expect(service.word).to eql("error") }
    it { expect(service.warnings?).to eql(true) }
    it { expect(service.warnings).to have_key(:word) }
  end

  context "with wrong arguments" do
    it { expect { WithConditions.run("Hello, world!") }.to raise_error(Light::Services::ArgTypeError) }
  end

  context "with two identical steps" do
    let(:class_code) do
      <<-RUBY
        class NoStep < ApplicationService
          step :hello_world
          step :hello_world
  
          private
          
          def hello_world
            # Hey, whats up?
          end
        end
  
        NoStep.run
      RUBY
    end

    it do
      expect { eval(class_code) }.to raise_error(Light::Services::Error)
    end
  end

  context "with not existed step specified in `after` parameter" do
    let(:class_code) do
      <<-RUBY
        class WithNotExistedStep < ApplicationService
          step :hello_world, after: :i_do_not_exist

          private
          
          def hello_world
            # Hey, whats up?
          end
        end
      RUBY
    end

    it do
      expect { eval(class_code) }.to raise_error(Light::Services::Error)
    end
  end

  context "with wrong arguments for context" do
    it { expect { WithConditions.with("Hello, world!") }.to raise_error(Light::Services::ArgTypeError) }
  end

  context "with not existed step specified in `after` parameter" do
    let(:class_code) do
      <<-RUBY
        class LoadErrorsFromString < ApplicationService
          step :hello_world

          private
          
          def hello_world
            self.current_user = User.new
            errors.from("Hello, world!")
          end
        end

        LoadErrorsFromString.run
      RUBY
    end

    it do
      expect { eval(class_code) }.to raise_error(Light::Services::Error)
    end
  end

  context "when I want 100% coverage" do
    let(:class_code) do
      <<-RUBY
        class WithNotExistedErrorMethod < ApplicationService
          step :hello_world

          private
          
          def hello_world
            errors.i_do_not_exist
          end
        end

        WithNotExistedErrorMethod.run
      RUBY
    end

    it do
      expect { eval(class_code) }.to raise_error(NoMethodError)
    end
  end
end

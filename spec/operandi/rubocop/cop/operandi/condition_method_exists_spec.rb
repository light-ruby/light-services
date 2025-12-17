# frozen_string_literal: true

require "rubocop"
require "rubocop/rspec/support"
require "operandi/rubocop"

RSpec.describe RuboCop::Cop::Operandi::ConditionMethodExists, :config do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  context "when condition method is missing" do
    it "registers an offense for missing if condition method" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          step :process, if: :should_process?
                             ^^^^^^^^^^^^^^^^ Operandi/ConditionMethodExists: Condition method `should_process?` has no corresponding method. For inherited methods, disable this line or add to ExcludedMethods.

          private

          def process; end
        end
      RUBY
    end

    it "registers an offense for missing unless condition method" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          step :notify, unless: :skip_notification?
                                ^^^^^^^^^^^^^^^^^^^ Operandi/ConditionMethodExists: Condition method `skip_notification?` has no corresponding method. For inherited methods, disable this line or add to ExcludedMethods.

          private

          def notify; end
        end
      RUBY
    end

    it "registers offenses for multiple missing condition methods" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          step :process, if: :should_process?
                             ^^^^^^^^^^^^^^^^ Operandi/ConditionMethodExists: Condition method `should_process?` has no corresponding method. For inherited methods, disable this line or add to ExcludedMethods.
          step :notify, unless: :skip?
                                ^^^^^^ Operandi/ConditionMethodExists: Condition method `skip?` has no corresponding method. For inherited methods, disable this line or add to ExcludedMethods.

          private

          def process; end
          def notify; end
        end
      RUBY
    end
  end

  context "when all condition methods exist" do
    it "does not register an offense when if condition method exists" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          step :process, if: :should_process?

          private

          def process; end
          def should_process?; true; end
        end
      RUBY
    end

    it "does not register an offense when unless condition method exists" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          step :notify, unless: :skip_notification?

          private

          def notify; end
          def skip_notification?; false; end
        end
      RUBY
    end

    it "does not register an offense when both conditions exist" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          step :process, if: :enabled?
          step :notify, unless: :silent?

          private

          def process; end
          def notify; end
          def enabled?; true; end
          def silent?; false; end
        end
      RUBY
    end
  end

  context "with proc conditions" do
    it "does not check proc conditions" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          step :process, if: -> { some_condition }

          private

          def process; end
        end
      RUBY
    end
  end

  context "with steps without conditions" do
    it "does not register an offense for steps without conditions" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          step :process
          step :notify, always: true

          private

          def process; end
          def notify; end
        end
      RUBY
    end
  end

  context "with ExcludedMethods option" do
    let(:config) do
      RuboCop::Config.new(
        "Operandi/ConditionMethodExists" => {
          "ExcludedMethods" => ["admin?", "guest?"],
        },
      )
    end

    it "does not register an offense for excluded methods" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          step :admin_action, if: :admin?
          step :guest_action, unless: :guest?

          private

          def admin_action; end
          def guest_action; end
        end
      RUBY
    end

    it "still registers an offense for non-excluded missing methods" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          step :admin_action, if: :admin?
          step :process, if: :enabled?
                             ^^^^^^^^^ Condition method `enabled?` has no corresponding method. For inherited methods, disable this line or add to ExcludedMethods.

          private

          def admin_action; end
          def process; end
        end
      RUBY
    end
  end

  context "without class definition" do
    it "does not crash on step calls outside a class" do
      expect_no_offenses(<<~RUBY)
        step :something, if: :condition?
      RUBY
    end
  end

  context "with argument predicates" do
    it "does not register an offense when condition matches arg predicate" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          arg :user, type: User, optional: true

          step :greet, if: :user?
          step :notify, if: :user

          private

          def greet; end
          def notify; end
        end
      RUBY
    end

    it "does not register an offense for multiple arg predicates" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          arg :user, type: User, optional: true
          arg :send_email, type: [TrueClass, FalseClass], default: false

          step :greet, if: :user?
          step :notify, if: :send_email?

          private

          def greet; end
          def notify; end
        end
      RUBY
    end

    it "registers an offense when condition does not match any arg" do
      expect_offense(<<~RUBY)
        class MyService < ApplicationService
          arg :user, type: User, optional: true

          step :process, if: :enabled?
                             ^^^^^^^^^ Operandi/ConditionMethodExists: Condition method `enabled?` has no corresponding method. For inherited methods, disable this line or add to ExcludedMethods.

          private

          def process; end
        end
      RUBY
    end
  end

  context "with output predicates" do
    it "does not register an offense when condition matches output predicate" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          output :result, type: Hash, optional: true

          step :log, if: :result?

          private

          def log; end
        end
      RUBY
    end

    it "does not register an offense for mixed arg and output predicates" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          arg :user, type: User, optional: true
          output :data, type: Hash, optional: true

          step :greet, if: :user?
          step :log, if: :data?

          private

          def greet; end
          def log; end
        end
      RUBY
    end
  end

  context "with attr_reader methods" do
    it "does not register an offense when condition matches attr_reader" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          attr_reader :enabled

          step :process, if: :enabled

          private

          def process; end
        end
      RUBY
    end

    it "does not register an offense for multiple attr_reader attributes" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          attr_reader :enabled, :active

          step :process, if: :enabled
          step :notify, if: :active

          private

          def process; end
          def notify; end
        end
      RUBY
    end
  end

  context "with attr_accessor methods" do
    it "does not register an offense when condition matches attr_accessor" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          attr_accessor :verbose

          step :log, if: :verbose

          private

          def log; end
        end
      RUBY
    end
  end

  context "with attr_writer methods" do
    it "does not register an offense when condition matches attr_writer" do
      expect_no_offenses(<<~RUBY)
        class MyService < ApplicationService
          attr_writer :skip_validation

          step :validate, unless: :skip_validation

          private

          def validate; end
        end
      RUBY
    end
  end
end

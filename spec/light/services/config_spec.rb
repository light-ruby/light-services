# frozen_string_literal: true

RSpec.describe Light::Services::Config do
  let(:config) { described_class.new }

  describe "#initialize" do
    it "sets all defaults" do
      described_class::DEFAULTS.each do |key, value|
        expect(config.public_send(key)).to eq(value)
      end
    end
  end

  describe "#reset_to_defaults!" do
    it "resets all values to defaults" do
      config.break_on_error = false
      config.raise_on_error = true
      config.use_transactions = false

      config.reset_to_defaults!

      expect(config.break_on_error).to be(true)
      expect(config.raise_on_error).to be(false)
      expect(config.use_transactions).to be(true)
    end
  end

  describe "#to_h" do
    it "returns hash with all config values" do
      hash = config.to_h
      expect(hash).to be_a(Hash)
      expect(hash.keys).to match_array(described_class::DEFAULTS.keys)
    end

    it "reflects current config values" do
      config.break_on_error = false
      expect(config.to_h[:break_on_error]).to be(false)
    end
  end

  describe "#merge" do
    it "merges config hash with provided hash" do
      merged = config.merge(custom_key: "value", break_on_error: false)
      expect(merged[:custom_key]).to eq("value")
      expect(merged[:break_on_error]).to be(false)
      expect(merged[:use_transactions]).to be(true)
    end

    it "does not modify original config" do
      config.merge(break_on_error: false)
      expect(config.break_on_error).to be(true)
    end
  end

  describe "attribute accessors" do
    it "has accessors for use_transactions" do
      config.use_transactions = false
      expect(config.use_transactions).to be(false)
    end

    it "has accessors for load_errors" do
      config.load_errors = false
      expect(config.load_errors).to be(false)
    end

    it "has accessors for break_on_error" do
      config.break_on_error = false
      expect(config.break_on_error).to be(false)
    end

    it "has accessors for raise_on_error" do
      config.raise_on_error = true
      expect(config.raise_on_error).to be(true)
    end

    it "has accessors for rollback_on_error" do
      config.rollback_on_error = false
      expect(config.rollback_on_error).to be(false)
    end

    it "has accessors for load_warnings" do
      config.load_warnings = false
      expect(config.load_warnings).to be(false)
    end

    it "has accessors for break_on_warning" do
      config.break_on_warning = true
      expect(config.break_on_warning).to be(true)
    end

    it "has accessors for raise_on_warning" do
      config.raise_on_warning = true
      expect(config.raise_on_warning).to be(true)
    end

    it "has accessors for rollback_on_warning" do
      config.rollback_on_warning = true
      expect(config.rollback_on_warning).to be(true)
    end
  end

  describe "DEFAULTS" do
    it "has expected default values" do
      expect(described_class::DEFAULTS).to eq({
        use_transactions: true,
        load_errors: true,
        break_on_error: true,
        raise_on_error: false,
        rollback_on_error: true,
        load_warnings: true,
        break_on_warning: false,
        raise_on_warning: false,
        rollback_on_warning: false,
        require_type: true,
      })
    end
  end

  describe "require_type" do
    it "has accessor for require_type" do
      config.require_type = false
      expect(config.require_type).to be(false)
    end

    it "defaults to true" do
      expect(config.require_type).to be(true)
    end
  end

  describe "require_type validation" do
    after do
      Light::Services.config.reset_to_defaults!
    end

    describe "global configuration" do
      context "when require_type is enabled globally" do
        before do
          Light::Services.config.require_type = true
        end

        it "raises MissingTypeError for argument without type" do
          expect do
            Class.new(Light::Services::Base) do
              arg :name
            end
          end.to raise_error(Light::Services::MissingTypeError, /Argument `name`.*must have a type specified/)
        end

        it "raises MissingTypeError for output without type" do
          expect do
            Class.new(Light::Services::Base) do
              output :result
            end
          end.to raise_error(Light::Services::MissingTypeError, /Output `result`.*must have a type specified/)
        end

        it "does not raise for argument with type" do
          expect do
            Class.new(Light::Services::Base) do
              arg :name, type: String
            end
          end.not_to raise_error
        end

        it "does not raise for output with type" do
          expect do
            Class.new(Light::Services::Base) do
              output :result, type: Hash
            end
          end.not_to raise_error
        end

        it "includes service class name in error message" do
          stub_const("TestServiceWithMissingType", Class.new(Light::Services::Base))
          expect do
            TestServiceWithMissingType.class_eval do
              arg :name
            end
          end.to raise_error(Light::Services::MissingTypeError, /TestServiceWithMissingType/)
        end
      end

      context "when require_type is disabled globally" do
        before do
          Light::Services.config.require_type = false
        end

        it "does not raise for argument without type" do
          expect do
            Class.new(Light::Services::Base) do
              arg :name
            end
          end.not_to raise_error
        end

        it "does not raise for output without type" do
          expect do
            Class.new(Light::Services::Base) do
              output :result
            end
          end.not_to raise_error
        end
      end
    end

    describe "class-level configuration" do
      context "when require_type is enabled at class level" do
        it "raises MissingTypeError for argument without type" do
          expect do
            Class.new(Light::Services::Base) do
              config require_type: true
              arg :name
            end
          end.to raise_error(Light::Services::MissingTypeError, /Argument `name`.*must have a type specified/)
        end

        it "raises MissingTypeError for output without type" do
          expect do
            Class.new(Light::Services::Base) do
              config require_type: true
              output :result
            end
          end.to raise_error(Light::Services::MissingTypeError, /Output `result`.*must have a type specified/)
        end

        it "does not raise for argument with type" do
          expect do
            Class.new(Light::Services::Base) do
              config require_type: true
              arg :name, type: String
            end
          end.not_to raise_error
        end

        it "does not raise for output with type" do
          expect do
            Class.new(Light::Services::Base) do
              config require_type: true
              output :result, type: Hash
            end
          end.not_to raise_error
        end
      end

      context "when require_type is disabled at class level but enabled globally" do
        before do
          Light::Services.config.require_type = true
        end

        it "class-level config overrides global config" do
          expect do
            Class.new(Light::Services::Base) do
              config require_type: false
              arg :name
            end
          end.not_to raise_error
        end
      end
    end

    describe "with different type formats" do
      before do
        Light::Services.config.require_type = true
      end

      it "accepts single type" do
        expect do
          Class.new(Light::Services::Base) do
            arg :name, type: String
          end
        end.not_to raise_error
      end

      it "accepts array of types" do
        expect do
          Class.new(Light::Services::Base) do
            arg :id, type: [String, Integer]
          end
        end.not_to raise_error
      end

      it "accepts custom class types" do
        custom_class = Class.new
        expect do
          Class.new(Light::Services::Base) do
            arg :data, type: custom_class
          end
        end.not_to raise_error
      end
    end
  end
end

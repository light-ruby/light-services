# frozen_string_literal: true

RSpec.describe Light::Services::Config do
  let(:config) { described_class.new }

  describe "#initialize" do
    it "sets all defaults" do
      described_class::DEFAULTS.each do |key, value|
        expect(config.get(key)).to eq(value)
      end
    end
  end

  describe "#set" do
    it "sets a config value" do
      config.set(:break_on_error, false)
      expect(config.break_on_error).to be(false)
    end

    it "sets custom keys" do
      config.set(:custom_key, "custom_value")
      expect(config.get(:custom_key)).to eq("custom_value")
    end
  end

  describe "#get" do
    it "gets a config value" do
      expect(config.get(:break_on_error)).to be(true)
    end

    it "returns nil for unset keys" do
      expect(config.get(:nonexistent_key)).to be_nil
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
                                                rollback_on_warning: false
                                              })
    end
  end
end

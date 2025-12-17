# frozen_string_literal: true

RSpec.describe Operandi::Message do
  describe "#initialize" do
    it "stores key and text" do
      message = described_class.new(:base, "error text")
      expect(message.key).to eq(:base)
      expect(message.text).to eq("error text")
    end
  end

  describe "#to_s" do
    it "returns the text" do
      message = described_class.new(:base, "error text")
      expect(message.to_s).to eq("error text")
    end
  end

  describe "#break?" do
    it "returns true when break opt is true" do
      message = described_class.new(:base, "text", break: true)
      expect(message.break?).to be(true)
    end

    it "returns false when break opt is false" do
      message = described_class.new(:base, "text", break: false)
      expect(message.break?).to be(false)
    end

    it "returns nil when break opt is not set" do
      message = described_class.new(:base, "text")
      expect(message.break?).to be_nil
    end
  end

  describe "#rollback?" do
    it "returns true when rollback opt is true" do
      message = described_class.new(:base, "text", rollback: true)
      expect(message.rollback?).to be(true)
    end

    it "returns false when rollback opt is false" do
      message = described_class.new(:base, "text", rollback: false)
      expect(message.rollback?).to be(false)
    end

    it "returns nil when rollback opt is not set" do
      message = described_class.new(:base, "text")
      expect(message.rollback?).to be_nil
    end
  end
end

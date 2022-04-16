# frozen_string_literal: true

RSpec.describe Light::Services do
  describe ".config" do
    it do
      Light::Services::Config::DEFAULTS.each_key do |param|
        expect(described_class.config).to respond_to(param).and respond_to("#{param}=")
      end
    end
  end

  describe ".configure" do
    it do
      described_class.configure do |config|
        expect(config).to be_a(Light::Services::Config)
      end
    end
  end
end

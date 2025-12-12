# frozen_string_literal: true

RSpec.describe Light::Services::Settings::TypeValidatable do
  describe "#setting_type" do
    it "raises NotImplementedError when not implemented" do
      dummy_class = Class.new do
        include Light::Services::Settings::TypeValidatable

        attr_reader :name

        def initialize
          @name = :test
          @type = String
          @service_class = "DummyService"
        end
      end

      instance = dummy_class.new
      expect { instance.validate_type!(123) }
        .to raise_error(NotImplementedError, "Subclasses must implement #setting_type")
    end
  end
end


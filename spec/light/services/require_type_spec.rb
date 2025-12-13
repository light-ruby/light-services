# frozen_string_literal: true

RSpec.describe "require_type configuration" do # rubocop:disable RSpec/DescribeClass
  around do |example|
    original_value = Light::Services.config.require_type
    example.run
    Light::Services.config.require_type = original_value
  end

  describe "when require_type is disabled" do
    before do
      Light::Services.config.require_type = false
    end

    it "allows arguments without type" do
      expect do
        Class.new(Light::Services::Base) do
          arg :name
        end
      end.not_to raise_error
    end

    it "allows outputs without type" do
      expect do
        Class.new(Light::Services::Base) do
          output :result
        end
      end.not_to raise_error
    end

    it "allows arguments with type" do
      expect do
        Class.new(Light::Services::Base) do
          arg :name, type: String
        end
      end.not_to raise_error
    end

    it "allows outputs with type" do
      expect do
        Class.new(Light::Services::Base) do
          output :result, type: Hash
        end
      end.not_to raise_error
    end
  end

  describe "when require_type is enabled (default)" do
    before do
      Light::Services.config.require_type = true
    end

    describe "arguments" do
      it "raises MissingTypeError when argument has no type" do
        expect do
          Class.new(Light::Services::Base) do
            arg :name
          end
        end.to raise_error(
          Light::Services::MissingTypeError,
          /Argument `name` in .* must have a type specified \(require_type is enabled\)/,
        )
      end

      it "raises MissingTypeError when argument only has optional" do
        expect do
          Class.new(Light::Services::Base) do
            arg :name, optional: true
          end
        end.to raise_error(
          Light::Services::MissingTypeError,
          /Argument `name` in .* must have a type specified/,
        )
      end

      it "raises MissingTypeError when argument only has default" do
        expect do
          Class.new(Light::Services::Base) do
            arg :name, default: "test"
          end
        end.to raise_error(
          Light::Services::MissingTypeError,
          /Argument `name` in .* must have a type specified/,
        )
      end

      it "allows arguments with type" do
        expect do
          Class.new(Light::Services::Base) do
            arg :name, type: String
          end
        end.not_to raise_error
      end

      it "allows arguments with type and other options" do
        expect do
          Class.new(Light::Services::Base) do
            arg :name, type: String, optional: true, default: "default"
          end
        end.not_to raise_error
      end

      it "allows arguments with multiple types" do
        expect do
          Class.new(Light::Services::Base) do
            arg :id, type: [String, Integer]
          end
        end.not_to raise_error
      end
    end

    describe "outputs" do
      it "raises MissingTypeError when output has no type" do
        expect do
          Class.new(Light::Services::Base) do
            output :result
          end
        end.to raise_error(
          Light::Services::MissingTypeError,
          /Output `result` in .* must have a type specified \(require_type is enabled\)/,
        )
      end

      it "raises MissingTypeError when output only has optional" do
        expect do
          Class.new(Light::Services::Base) do
            output :result, optional: true
          end
        end.to raise_error(
          Light::Services::MissingTypeError,
          /Output `result` in .* must have a type specified/,
        )
      end

      it "raises MissingTypeError when output only has default" do
        expect do
          Class.new(Light::Services::Base) do
            output :result, default: {}
          end
        end.to raise_error(
          Light::Services::MissingTypeError,
          /Output `result` in .* must have a type specified/,
        )
      end

      it "allows outputs with type" do
        expect do
          Class.new(Light::Services::Base) do
            output :result, type: Hash
          end
        end.not_to raise_error
      end

      it "allows outputs with type and other options" do
        expect do
          Class.new(Light::Services::Base) do
            output :result, type: Hash, optional: true, default: -> { {} }
          end
        end.not_to raise_error
      end

      it "allows outputs with multiple types" do
        expect do
          Class.new(Light::Services::Base) do
            output :data, type: [Hash, Array]
          end
        end.not_to raise_error
      end
    end

    describe "mixed arguments and outputs" do
      it "raises error for first field without type" do
        expect do
          Class.new(Light::Services::Base) do
            arg :input, type: String
            arg :name # This should raise
            output :result, type: Hash
          end
        end.to raise_error(
          Light::Services::MissingTypeError,
          /Argument `name` in .* must have a type specified/,
        )
      end

      it "allows service with all typed fields" do
        expect do
          Class.new(Light::Services::Base) do
            arg :input, type: String
            arg :count, type: Integer, optional: true, default: 10
            output :result, type: Hash
            output :status, type: String
          end
        end.not_to raise_error
      end
    end
  end

  describe "global configuration via configure block" do
    it "can be set via configure block" do
      Light::Services.configure do |config|
        config.require_type = true
      end

      expect(Light::Services.config.require_type).to be(true)
    end
  end
end

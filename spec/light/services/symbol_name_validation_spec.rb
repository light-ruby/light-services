# frozen_string_literal: true

RSpec.describe "Symbol Name Validation" do # rubocop:disable RSpec/DescribeClass
  describe "argument name validation" do
    it "raises InvalidNameError when argument name is a String" do
      expect do
        Class.new(Light::Services::Base) do
          arg "name"
        end
      end.to raise_error(
        Light::Services::InvalidNameError,
        /Argument name must be a Symbol, got String \("name"\)/,
      )
    end

    it "raises InvalidNameError when argument name is an Integer" do
      expect do
        Class.new(Light::Services::Base) do
          arg 123
        end
      end.to raise_error(
        Light::Services::InvalidNameError,
        /Argument name must be a Symbol, got Integer \(123\)/,
      )
    end

    it "raises InvalidNameError when argument name is nil" do
      expect do
        Class.new(Light::Services::Base) do
          arg nil
        end
      end.to raise_error(
        Light::Services::InvalidNameError,
        /Argument name must be a Symbol, got NilClass \(nil\)/,
      )
    end

    it "allows valid symbol argument names" do
      expect do
        Class.new(Light::Services::Base) do
          arg :user_name, type: String
          arg :email, type: String
        end
      end.not_to raise_error
    end
  end

  describe "output name validation" do
    it "raises InvalidNameError when output name is a String" do
      expect do
        Class.new(Light::Services::Base) do
          output "result"
        end
      end.to raise_error(
        Light::Services::InvalidNameError,
        /Output name must be a Symbol, got String \("result"\)/,
      )
    end

    it "raises InvalidNameError when output name is an Integer" do
      expect do
        Class.new(Light::Services::Base) do
          output 456
        end
      end.to raise_error(
        Light::Services::InvalidNameError,
        /Output name must be a Symbol, got Integer \(456\)/,
      )
    end

    it "raises InvalidNameError when output name is nil" do
      expect do
        Class.new(Light::Services::Base) do
          output nil
        end
      end.to raise_error(
        Light::Services::InvalidNameError,
        /Output name must be a Symbol, got NilClass \(nil\)/,
      )
    end

    it "allows valid symbol output names" do
      expect do
        Class.new(Light::Services::Base) do
          output :result, type: Hash
          output :status, type: String
        end
      end.not_to raise_error
    end
  end

  describe "step name validation" do
    it "raises InvalidNameError when step name is a String" do
      expect do
        Class.new(Light::Services::Base) do
          step "process"
        end
      end.to raise_error(
        Light::Services::InvalidNameError,
        /Step name must be a Symbol, got String \("process"\)/,
      )
    end

    it "raises InvalidNameError when step name is an Integer" do
      expect do
        Class.new(Light::Services::Base) do
          step 789
        end
      end.to raise_error(
        Light::Services::InvalidNameError,
        /Step name must be a Symbol, got Integer \(789\)/,
      )
    end

    it "raises InvalidNameError when step name is nil" do
      expect do
        Class.new(Light::Services::Base) do
          step nil
        end
      end.to raise_error(
        Light::Services::InvalidNameError,
        /Step name must be a Symbol, got NilClass \(nil\)/,
      )
    end

    it "raises InvalidNameError when step name is an Array" do
      expect do
        Class.new(Light::Services::Base) do
          step [:step1, :step2]
        end
      end.to raise_error(
        Light::Services::InvalidNameError,
        /Step name must be a Symbol, got Array/,
      )
    end

    it "allows valid symbol step names" do
      expect do
        Class.new(Light::Services::Base) do
          step :validate_input
          step :process_data
        end
      end.not_to raise_error
    end
  end
end

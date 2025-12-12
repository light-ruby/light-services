# frozen_string_literal: true

RSpec.describe "Dry Types Support" do # rubocop:disable RSpec/DescribeClass
  describe WithDryTypes do
    describe "argument validation with dry-types" do
      context "with valid strict string" do
        subject(:service) { described_class.run(name: "John", age: 25) }

        it { is_expected.to be_success }
        it { expect(service.greeting).to eq("Hello, John!") }
        it { expect(service.user_age).to eq(25) }
      end

      context "with coercible integer (string to integer)" do
        subject(:service) { described_class.run(name: "Jane", age: "30") }

        it { is_expected.to be_success }
        it { expect(service.user_age).to eq(30) }
      end

      context "with invalid strict string (integer instead of string)" do
        it "raises ArgTypeError" do
          expect { described_class.run(name: 123, age: 25) }
            .to raise_error(Light::Services::ArgTypeError, /`name`.*123 violates constraints/)
        end
      end

      context "with invalid coercible integer" do
        it "raises ArgTypeError" do
          expect { described_class.run(name: "John", age: "not a number") }
            .to raise_error(Light::Services::ArgTypeError, /`age`/)
        end
      end

      context "with enum validation" do
        it "accepts valid enum value" do
          service = described_class.run(name: "John", age: 25, status: "active")
          expect(service).to be_success
          expect(service.full_data[:status]).to eq("active")
        end

        it "raises error for invalid enum value" do
          expect { described_class.run(name: "John", age: 25, status: "unknown") }
            .to raise_error(Light::Services::ArgTypeError, /`status`/)
        end

        it "uses default enum value" do
          service = described_class.run(name: "John", age: 25)
          expect(service.full_data[:status]).to eq("pending")
        end
      end

      context "with constrained string (email format)" do
        it "accepts valid email" do
          service = described_class.run(name: "John", age: 25, email: "john@example.com")
          expect(service).to be_success
          expect(service.full_data[:email]).to eq("john@example.com")
        end

        it "raises error for invalid email format" do
          expect { described_class.run(name: "John", age: 25, email: "invalid-email") }
            .to raise_error(Light::Services::ArgTypeError, /`email`/)
        end
      end

      context "with array of strings" do
        it "accepts valid array of strings" do
          service = described_class.run(name: "John", age: 25, tags: ["ruby", "rails"])
          expect(service).to be_success
          expect(service.full_data[:tags]).to eq(["ruby", "rails"])
        end

        it "raises error for array with invalid elements" do
          expect { described_class.run(name: "John", age: 25, tags: ["ruby", 123]) }
            .to raise_error(Light::Services::ArgTypeError, /`tags`/)
        end
      end
    end

    describe "output validation with dry-types" do
      context "with valid outputs" do
        subject(:service) { described_class.run(name: "John", age: 25) }

        it { is_expected.to be_success }
        it { expect(service.greeting).to be_a(String) }
        it { expect(service.user_age).to be_a(Integer) }
        it { expect(service.full_data).to be_a(Hash) }
      end
    end

    describe "mixing dry-types with optional fields" do
      context "when optional field is nil" do
        subject(:service) { described_class.run(name: "John", age: 25) }

        it { is_expected.to be_success }
        it { expect(service.full_data[:email]).to be_nil }
        it { expect(service.full_data[:tags]).to eq([]) }
      end
    end
  end
end

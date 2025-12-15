# frozen_string_literal: true

# Mock Solargraph module structure for testing
module Solargraph
  module LightServices
  end
end

require_relative "../../../lib/solargraph/light_services/type_mapper"

RSpec.describe Solargraph::LightServices::TypeMapper do
  describe ".resolve" do
    context "with nil input" do
      it "returns nil" do
        expect(described_class.resolve(nil)).to be_nil
      end
    end

    context "with simple Ruby class types" do
      it "passes through standard Ruby classes" do
        expect(described_class.resolve("String")).to eq("String")
        expect(described_class.resolve("Integer")).to eq("Integer")
        expect(described_class.resolve("Hash")).to eq("Hash")
        expect(described_class.resolve("Array")).to eq("Array")
      end

      it "passes through custom class types" do
        expect(described_class.resolve("User")).to eq("User")
        expect(described_class.resolve("Order")).to eq("Order")
      end

      it "passes through namespaced class types" do
        expect(described_class.resolve("Stripe::Charge")).to eq("Stripe::Charge")
        expect(described_class.resolve("MyApp::Config")).to eq("MyApp::Config")
      end
    end

    context "with dry-types simple types" do
      it "maps Types::String to String" do
        expect(described_class.resolve("Types::String")).to eq("String")
      end

      it "maps Types::Integer to Integer" do
        expect(described_class.resolve("Types::Integer")).to eq("Integer")
      end

      it "maps Types::Float to Float" do
        expect(described_class.resolve("Types::Float")).to eq("Float")
      end

      it "maps Types::Bool to Boolean" do
        expect(described_class.resolve("Types::Bool")).to eq("Boolean")
      end

      it "maps Types::Array to Array" do
        expect(described_class.resolve("Types::Array")).to eq("Array")
      end

      it "maps Types::Hash to Hash" do
        expect(described_class.resolve("Types::Hash")).to eq("Hash")
      end

      it "maps Types::Symbol to Symbol" do
        expect(described_class.resolve("Types::Symbol")).to eq("Symbol")
      end

      it "maps Types::Date to Date" do
        expect(described_class.resolve("Types::Date")).to eq("Date")
      end

      it "maps Types::DateTime to DateTime" do
        expect(described_class.resolve("Types::DateTime")).to eq("DateTime")
      end

      it "maps Types::Time to Time" do
        expect(described_class.resolve("Types::Time")).to eq("Time")
      end

      it "maps Types::Decimal to BigDecimal" do
        expect(described_class.resolve("Types::Decimal")).to eq("BigDecimal")
      end

      it "maps Types::Nil to nil" do
        expect(described_class.resolve("Types::Nil")).to eq("nil")
      end

      it "maps Types::Any to Object" do
        expect(described_class.resolve("Types::Any")).to eq("Object")
      end
    end

    context "with dry-types strict types" do
      it "maps Types::Strict::String to String" do
        expect(described_class.resolve("Types::Strict::String")).to eq("String")
      end

      it "maps Types::Strict::Integer to Integer" do
        expect(described_class.resolve("Types::Strict::Integer")).to eq("Integer")
      end

      it "maps Types::Strict::Bool to Boolean" do
        expect(described_class.resolve("Types::Strict::Bool")).to eq("Boolean")
      end

      it "maps Types::Strict::Array to Array" do
        expect(described_class.resolve("Types::Strict::Array")).to eq("Array")
      end

      it "maps Types::Strict::Hash to Hash" do
        expect(described_class.resolve("Types::Strict::Hash")).to eq("Hash")
      end
    end

    context "with dry-types coercible types" do
      it "maps Types::Coercible::String to String" do
        expect(described_class.resolve("Types::Coercible::String")).to eq("String")
      end

      it "maps Types::Coercible::Integer to Integer" do
        expect(described_class.resolve("Types::Coercible::Integer")).to eq("Integer")
      end

      it "maps Types::Coercible::Symbol to Symbol" do
        expect(described_class.resolve("Types::Coercible::Symbol")).to eq("Symbol")
      end
    end

    context "with parameterized dry-types" do
      it "extracts base type from Types::Array.of(...)" do
        expect(described_class.resolve("Types::Array.of(Types::String)")).to eq("Array")
      end

      it "extracts base type from Types::Hash.schema(...)" do
        expect(described_class.resolve("Types::Hash.schema(name: Types::String)")).to eq("Hash")
      end

      it "extracts base type from Types::String.constrained(...)" do
        expect(described_class.resolve("Types::String.constrained(format: /@/)")).to eq("String")
      end

      it "extracts base type from Types::String.optional" do
        expect(described_class.resolve("Types::String.optional")).to eq("String")
      end

      it "extracts base type from Types::String.default(...)" do
        expect(described_class.resolve("Types::String.default('')")).to eq("String")
      end
    end

    context "with non-type strings" do
      it "returns nil for lowercase strings" do
        expect(described_class.resolve("lowercase")).to be_nil
      end

      it "returns nil for snake_case strings" do
        expect(described_class.resolve("snake_case")).to be_nil
      end
    end
  end

  describe "custom type mappings" do
    after do
      Light::Services.config.solargraph_type_mappings = {}
    end

    context "with custom type mappings configured" do
      before do
        Light::Services.config.solargraph_type_mappings = {
          "Types::UUID" => "String",
          "Types::Money" => "BigDecimal",
          "CustomTypes::Email" => "String",
        }
      end

      it "maps custom Types::UUID to String" do
        expect(described_class.resolve("Types::UUID")).to eq("String")
      end

      it "maps custom Types::Money to BigDecimal" do
        expect(described_class.resolve("Types::Money")).to eq("BigDecimal")
      end

      it "maps custom namespaced types" do
        expect(described_class.resolve("CustomTypes::Email")).to eq("String")
      end

      it "still uses default mappings for non-custom types" do
        expect(described_class.resolve("Types::Strict::String")).to eq("String")
      end
    end

    context "when custom mapping overrides default" do
      before do
        Light::Services.config.solargraph_type_mappings = {
          "Types::String" => "CustomString",
        }
      end

      it "custom mapping takes precedence over default" do
        expect(described_class.resolve("Types::String")).to eq("CustomString")
      end

      it "other defaults still work" do
        expect(described_class.resolve("Types::Integer")).to eq("Integer")
      end
    end
  end
end

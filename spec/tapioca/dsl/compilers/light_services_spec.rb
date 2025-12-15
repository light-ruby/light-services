# frozen_string_literal: true

require "spec_helper"

# Mock T module if sorbet-runtime is not available
# Must be defined before Tapioca mocks since Compiler extends T::Sig
unless defined?(T::Sig)
  module T
    def self.sig(&block); end

    def self.type_member
      # Returns a placeholder for type_member
      nil
    end

    module Sig
      def sig(&block); end
    end
  end
end

# Mock Tapioca modules for testing without tapioca dependency
module Tapioca
  module Dsl
    class Compiler
      extend T::Sig

      class << self
        extend T::Sig

        def type_member
          # Mock type_member for testing
          nil
        end

        def all_classes
          ObjectSpace.each_object(Class)
        end
      end

      attr_reader :constant, :root

      def initialize(constant, root)
        @constant = constant
        @root = root
      end

      def create_param(name, type:)
        MockParam.new(name, type)
      end
    end
  end
end

# Mock RBI module
module RBI
  class Scope
    attr_reader :methods

    def initialize
      @methods = []
    end

    def create_method(name, parameters: [], return_type: nil, visibility: nil, class_method: false)
      @methods << MockMethod.new(name, parameters, return_type, visibility, class_method)
    end
  end

  class Tree
    def create_path(_constant)
      scope = Scope.new
      yield scope
      scope
    end
  end

  class Private
    def to_s
      "private"
    end
  end
end

# Mock classes for testing
class MockParam
  attr_reader :name, :type

  def initialize(name, type)
    @name = name
    @type = type
  end
end

class MockMethod
  attr_reader :name, :parameters, :return_type, :visibility, :class_method

  def initialize(name, parameters, return_type, visibility, class_method)
    @name = name
    @parameters = parameters
    @return_type = return_type
    @visibility = visibility
    @class_method = class_method
  end

  def private?
    visibility.is_a?(RBI::Private)
  end
end

require_relative "../../../../lib/tapioca/dsl/compilers/light_services"

RSpec.describe Tapioca::Dsl::Compilers::LightServices do
  let(:root) { RBI::Tree.new }
  let(:compiler) { described_class.new(service_class, root) }

  # Helper to find a method by name in the generated scope
  def find_method(scope, name)
    scope.methods.find { |m| m.name == name }
  end

  describe ".gather_constants" do
    it "returns all Light::Services::Base descendants" do
      constants = described_class.gather_constants.to_a

      expect(constants).to include(CreateService)
      expect(constants).to include(User::Create)
    end

    it "excludes Light::Services::Base itself" do
      constants = described_class.gather_constants.to_a

      expect(constants).not_to include(Light::Services::Base)
    end

    it "excludes anonymous classes" do
      anonymous_service = Class.new(Light::Services::Base) do
        arg :value, type: String
      end

      constants = described_class.gather_constants.to_a

      expect(constants).not_to include(anonymous_service)
    end
  end

  describe "#decorate" do
    context "with simple string argument" do
      let(:service_class) do
        Class.new(Light::Services::Base) do
          def self.name
            "TestStringArgService"
          end

          arg :name, type: String
        end
      end

      it "generates getter method with correct return type" do
        scope = compiler.decorate

        getter = find_method(scope, "name")
        expect(getter).not_to be_nil
        expect(getter.return_type).to eq("::String")
      end

      it "generates predicate method with T::Boolean return type" do
        scope = compiler.decorate

        predicate = find_method(scope, "name?")
        expect(predicate).not_to be_nil
        expect(predicate.return_type).to eq("T::Boolean")
      end

      it "generates private setter method" do
        scope = compiler.decorate

        setter = find_method(scope, "name=")
        expect(setter).not_to be_nil
        expect(setter.private?).to be(true)
        expect(setter.return_type).to eq("::String")
        expect(setter.parameters.first.type).to eq("::String")
      end
    end

    context "with optional argument" do
      let(:service_class) do
        Class.new(Light::Services::Base) do
          def self.name
            "TestOptionalArgService"
          end

          arg :email, type: String, optional: true
        end
      end

      it "generates getter with nilable return type" do
        scope = compiler.decorate

        getter = find_method(scope, "email")
        expect(getter.return_type).to eq("T.nilable(::String)")
      end

      it "generates setter with nilable parameter type" do
        scope = compiler.decorate

        setter = find_method(scope, "email=")
        expect(setter.parameters.first.type).to eq("T.nilable(::String)")
      end
    end

    context "with multiple types (union)" do
      let(:service_class) do
        Class.new(Light::Services::Base) do
          def self.name
            "TestUnionArgService"
          end

          arg :id, type: [String, Integer]
        end
      end

      it "generates getter with T.any union type" do
        scope = compiler.decorate

        getter = find_method(scope, "id")
        expect(getter.return_type).to eq("T.any(::String, ::Integer)")
      end
    end

    context "with boolean type (TrueClass, FalseClass)" do
      let(:service_class) do
        Class.new(Light::Services::Base) do
          def self.name
            "TestBooleanArgService"
          end

          arg :active, type: [TrueClass, FalseClass]
        end
      end

      it "generates getter with T::Boolean type" do
        scope = compiler.decorate

        getter = find_method(scope, "active")
        expect(getter.return_type).to eq("T::Boolean")
      end
    end

    context "with output" do
      let(:service_class) do
        Class.new(Light::Services::Base) do
          def self.name
            "TestOutputService"
          end

          output :result, type: Hash
        end
      end

      it "generates all three methods for output" do
        scope = compiler.decorate

        expect(find_method(scope, "result")).not_to be_nil
        expect(find_method(scope, "result?")).not_to be_nil
        expect(find_method(scope, "result=")).not_to be_nil
      end

      it "generates getter with correct return type" do
        scope = compiler.decorate

        getter = find_method(scope, "result")
        expect(getter.return_type).to eq("::Hash")
      end
    end

    context "with both arguments and outputs" do
      let(:service_class) do
        Class.new(Light::Services::Base) do
          def self.name
            "TestMixedService"
          end

          arg :input, type: String
          output :output, type: Integer
        end
      end

      it "generates methods for both arguments and outputs" do
        scope = compiler.decorate

        expect(find_method(scope, "input")).not_to be_nil
        expect(find_method(scope, "output")).not_to be_nil
      end

      it "generates 6 methods total (3 per field)" do
        scope = compiler.decorate

        expect(scope.methods.size).to eq(6)
      end
    end

    context "with no arguments or outputs" do
      let(:service_class) do
        Class.new(Light::Services::Base) do
          def self.name
            "TestEmptyService"
          end
        end
      end

      it "returns nil when there are no arguments or outputs" do
        result = compiler.decorate

        expect(result).to be_nil
      end
    end

    context "with custom class type" do
      let(:service_class) do
        Class.new(Light::Services::Base) do
          def self.name
            "TestCustomClassService"
          end

          arg :user, type: User
          output :order, type: Order
        end
      end

      it "generates getter with fully qualified class name" do
        scope = compiler.decorate

        user_getter = find_method(scope, "user")
        expect(user_getter.return_type).to eq("::User")

        order_getter = find_method(scope, "order")
        expect(order_getter.return_type).to eq("::Order")
      end
    end

    context "with inherited arguments" do
      let(:parent_service) do
        Class.new(Light::Services::Base) do
          def self.name
            "ParentService"
          end

          arg :parent_arg, type: String
        end
      end

      let(:service_class) do
        parent = parent_service
        Class.new(parent) do
          def self.name
            "ChildService"
          end

          arg :child_arg, type: Integer
        end
      end

      it "generates methods for both parent and child arguments" do
        scope = compiler.decorate

        expect(find_method(scope, "parent_arg")).not_to be_nil
        expect(find_method(scope, "child_arg")).not_to be_nil
      end
    end
  end

  describe "type mapping" do
    describe "DRY_TYPE_MAPPINGS" do
      it "maps Types::String to ::String" do
        expect(described_class::DRY_TYPE_MAPPINGS["Types::String"]).to eq("::String")
      end

      it "maps Types::Bool to T::Boolean" do
        expect(described_class::DRY_TYPE_MAPPINGS["Types::Bool"]).to eq("T::Boolean")
      end

      it "maps Types::Integer to ::Integer" do
        expect(described_class::DRY_TYPE_MAPPINGS["Types::Integer"]).to eq("::Integer")
      end

      it "maps Types::Any to T.untyped" do
        expect(described_class::DRY_TYPE_MAPPINGS["Types::Any"]).to eq("T.untyped")
      end
    end
  end

  describe "#resolve_type" do
    let(:service_class) do
      Class.new(Light::Services::Base) do
        def self.name
          "ResolveTypeTestService"
        end

        arg :test, type: String
      end
    end

    context "when type is nil" do
      it "returns T.untyped" do
        field = Light::Services::Settings::Field.new(:no_type, service_class, field_type: :argument)
        field.instance_variable_set(:@type, nil)

        result = compiler.send(:resolve_type, field)

        expect(result).to eq("T.untyped")
      end
    end

    context "when type is an unrecognized object" do
      it "returns T.untyped" do
        field = Light::Services::Settings::Field.new(:unknown_type, service_class, field_type: :argument)
        field.instance_variable_set(:@type, "some random string")

        result = compiler.send(:resolve_type, field)

        expect(result).to eq("T.untyped")
      end
    end
  end

  describe "dry-types integration" do
    let(:service_class) { WithDryTypes }

    context "with Types::Strict::String" do
      it "generates getter with ::String return type" do
        scope = compiler.decorate

        getter = find_method(scope, "name")
        expect(getter.return_type).to eq("::String")
      end
    end

    context "with Types::Coercible::Integer" do
      it "generates getter with ::Integer return type" do
        scope = compiler.decorate

        getter = find_method(scope, "age")
        expect(getter.return_type).to eq("::Integer")
      end
    end

    context "with Types::String.constrained (parameterized)" do
      it "generates getter with ::String return type (base type)" do
        scope = compiler.decorate

        getter = find_method(scope, "email")
        # email is optional, so it's nilable
        expect(getter.return_type).to eq("T.nilable(::String)")
      end
    end

    context "with Types::String.enum (parameterized)" do
      it "generates getter with ::String return type (base type)" do
        scope = compiler.decorate

        getter = find_method(scope, "status")
        expect(getter.return_type).to eq("::String")
      end
    end

    context "with Types::Array.of (parameterized)" do
      it "generates getter with ::Array return type (base type)" do
        scope = compiler.decorate

        getter = find_method(scope, "tags")
        # tags is optional
        expect(getter.return_type).to eq("T.nilable(::Array)")
      end
    end

    context "with Types::Hash.schema (parameterized)" do
      it "generates getter with ::Hash return type (base type)" do
        scope = compiler.decorate

        getter = find_method(scope, "metadata")
        # metadata is optional
        expect(getter.return_type).to eq("T.nilable(::Hash)")
      end
    end

    context "with output using Types::Strict::String" do
      it "generates getter with ::String return type" do
        scope = compiler.decorate

        getter = find_method(scope, "greeting")
        expect(getter.return_type).to eq("::String")
      end
    end

    context "with output using Types::Strict::Integer" do
      it "generates getter with ::Integer return type" do
        scope = compiler.decorate

        getter = find_method(scope, "user_age")
        expect(getter.return_type).to eq("::Integer")
      end
    end

    context "with output using Types::Hash (optional)" do
      it "generates getter with T.nilable(::Hash) return type" do
        scope = compiler.decorate

        getter = find_method(scope, "full_data")
        expect(getter.return_type).to eq("T.nilable(::Hash)")
      end
    end

    it "generates all expected methods for dry-types service" do
      scope = compiler.decorate

      # Arguments: current_user (inherited), name, age, email, status, tags, metadata (7 fields × 3 methods = 21)
      # Outputs: greeting, user_age, full_data (3 fields × 3 methods = 9)
      # Total: 30 methods
      expect(scope.methods.size).to eq(30)
    end
  end

  describe "T.untyped scenarios" do
    context "when argument has no type option" do
      let(:service_class) do
        # Create a service with a field that has no type
        klass = Class.new(Light::Services::Base) do
          def self.name
            "NoTypeService"
          end
        end

        # Manually create a field without type validation
        field = Light::Services::Settings::Field.new(:untyped_arg, klass, field_type: :argument)
        field.instance_variable_set(:@type, nil)
        klass.own_arguments[:untyped_arg] = field
        klass.instance_variable_set(:@arguments, nil) # Clear memoized

        klass
      end

      it "generates getter with T.untyped return type" do
        scope = compiler.decorate

        getter = find_method(scope, "untyped_arg")
        expect(getter.return_type).to eq("T.untyped")
      end

      it "generates setter with T.untyped parameter type" do
        scope = compiler.decorate

        setter = find_method(scope, "untyped_arg=")
        expect(setter.parameters.first.type).to eq("T.untyped")
      end

      it "still generates predicate with T::Boolean" do
        scope = compiler.decorate

        predicate = find_method(scope, "untyped_arg?")
        expect(predicate.return_type).to eq("T::Boolean")
      end
    end

    context "when optional field has no type" do
      let(:service_class) do
        klass = Class.new(Light::Services::Base) do
          def self.name
            "OptionalNoTypeService"
          end
        end

        # Manually create an optional field without type
        field = Light::Services::Settings::Field.new(:optional_untyped, klass, field_type: :argument, optional: true)
        field.instance_variable_set(:@type, nil)
        klass.own_arguments[:optional_untyped] = field
        klass.instance_variable_set(:@arguments, nil)

        klass
      end

      it "generates getter with T.untyped (not nilable-wrapped)" do
        scope = compiler.decorate

        getter = find_method(scope, "optional_untyped")
        # T.untyped already includes nil, so no wrapping
        expect(getter.return_type).to eq("T.untyped")
      end
    end

    context "when dry-type doesn't respond to :primitive" do
      let(:service_class) do
        klass = Class.new(Light::Services::Base) do
          def self.name
            "DryTypeNoPrimitiveService"
          end
        end

        # Create a mock dry-type that doesn't respond to :primitive
        mock_dry_type = Object.new
        mock_dry_type.define_singleton_method(:to_s) { "CustomType::Unknown" }
        # Make it pass the dry_type? check
        stub_const("Dry::Types::Type", Class.new) unless defined?(Dry::Types::Type)
        mock_dry_type.define_singleton_method(:is_a?) do |klass|
          klass == Dry::Types::Type || super(klass)
        end

        field = Light::Services::Settings::Field.new(:no_primitive, klass, field_type: :argument)
        field.instance_variable_set(:@type, mock_dry_type)
        klass.own_arguments[:no_primitive] = field
        klass.instance_variable_set(:@arguments, nil)

        klass
      end

      it "returns T.untyped when type doesn't respond to :primitive" do
        scope = compiler.decorate

        getter = find_method(scope, "no_primitive")
        expect(getter.return_type).to eq("T.untyped")
      end
    end

    context "when dry-type primitive is not a Class or Module" do
      let(:service_class) do
        klass = Class.new(Light::Services::Base) do
          def self.name
            "DryTypeInvalidPrimitiveService"
          end
        end

        # Create a mock dry-type with invalid primitive
        mock_dry_type = Object.new
        mock_dry_type.define_singleton_method(:to_s) { "CustomType::InvalidPrimitive" }
        mock_dry_type.define_singleton_method(:primitive) { "not_a_class" }
        stub_const("Dry::Types::Type", Class.new) unless defined?(Dry::Types::Type)
        mock_dry_type.define_singleton_method(:is_a?) do |klass|
          klass == Dry::Types::Type || super(klass)
        end

        field = Light::Services::Settings::Field.new(:invalid_primitive, klass, field_type: :argument)
        field.instance_variable_set(:@type, mock_dry_type)
        klass.own_arguments[:invalid_primitive] = field
        klass.instance_variable_set(:@arguments, nil)

        klass
      end

      it "returns T.untyped when primitive is not a Class or Module" do
        scope = compiler.decorate

        getter = find_method(scope, "invalid_primitive")
        expect(getter.return_type).to eq("T.untyped")
      end
    end

    context "when dry-type primitive raises an error" do
      let(:service_class) do
        klass = Class.new(Light::Services::Base) do
          def self.name
            "DryTypeErrorPrimitiveService"
          end
        end

        # Create a mock dry-type that raises an error on primitive
        mock_dry_type = Object.new
        mock_dry_type.define_singleton_method(:to_s) { "CustomType::ErrorPrimitive" }
        mock_dry_type.define_singleton_method(:primitive) { raise StandardError, "boom" }
        stub_const("Dry::Types::Type", Class.new) unless defined?(Dry::Types::Type)
        mock_dry_type.define_singleton_method(:is_a?) do |klass|
          klass == Dry::Types::Type || super(klass)
        end

        field = Light::Services::Settings::Field.new(:error_primitive, klass, field_type: :argument)
        field.instance_variable_set(:@type, mock_dry_type)
        klass.own_arguments[:error_primitive] = field
        klass.instance_variable_set(:@arguments, nil)

        klass
      end

      it "returns T.untyped when primitive raises an error" do
        scope = compiler.decorate

        getter = find_method(scope, "error_primitive")
        expect(getter.return_type).to eq("T.untyped")
      end
    end
  end

  describe "edge cases" do
    context "with module type instead of class" do
      let(:service_class) do
        Class.new(Light::Services::Base) do
          def self.name
            "ModuleTypeService"
          end

          arg :enumerable_thing, type: Enumerable
        end
      end

      it "generates getter with module name" do
        scope = compiler.decorate

        getter = find_method(scope, "enumerable_thing")
        expect(getter.return_type).to eq("::Enumerable")
      end
    end

    context "with array containing single type" do
      let(:service_class) do
        Class.new(Light::Services::Base) do
          def self.name
            "SingleTypeArrayService"
          end

          arg :value, type: [String]
        end
      end

      it "generates getter with single type (not T.any)" do
        scope = compiler.decorate

        getter = find_method(scope, "value")
        expect(getter.return_type).to eq("::String")
      end
    end

    context "with duplicate types in array" do
      let(:service_class) do
        Class.new(Light::Services::Base) do
          def self.name
            "DuplicateTypeService"
          end

          arg :value, type: [String, String]
        end
      end

      it "deduplicates types" do
        scope = compiler.decorate

        getter = find_method(scope, "value")
        expect(getter.return_type).to eq("::String")
      end
    end

    context "with array containing dry-types" do
      let(:service_class) do
        Class.new(Light::Services::Base) do
          def self.name
            "ArrayWithDryTypeService"
          end

          arg :value, type: [Types::Strict::String, Types::Strict::Integer]
        end
      end

      it "resolves dry-types within array to T.any union" do
        scope = compiler.decorate

        getter = find_method(scope, "value")
        expect(getter.return_type).to eq("T.any(::String, ::Integer)")
      end
    end

    context "with array containing mixed Ruby classes and dry-types" do
      let(:service_class) do
        Class.new(Light::Services::Base) do
          def self.name
            "MixedArrayTypeService"
          end

          arg :value, type: [String, Types::Strict::Integer]
        end
      end

      it "resolves both Ruby classes and dry-types" do
        scope = compiler.decorate

        getter = find_method(scope, "value")
        expect(getter.return_type).to eq("T.any(::String, ::Integer)")
      end
    end

    context "with array containing unrecognized type" do
      let(:service_class) do
        klass = Class.new(Light::Services::Base) do
          def self.name
            "ArrayWithUnknownTypeService"
          end
        end

        # Manually create a field with an array containing an unrecognized type
        field = Light::Services::Settings::Field.new(:mixed_unknown, klass, field_type: :argument)
        field.instance_variable_set(:@type, [String, "unknown_type", Integer])
        klass.own_arguments[:mixed_unknown] = field
        klass.instance_variable_set(:@arguments, nil)

        klass
      end

      it "includes T.untyped for unrecognized types in union" do
        scope = compiler.decorate

        getter = find_method(scope, "mixed_unknown")
        expect(getter.return_type).to eq("T.any(::String, T.untyped, ::Integer)")
      end
    end
  end
end

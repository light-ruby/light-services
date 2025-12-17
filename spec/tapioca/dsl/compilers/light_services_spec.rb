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

        # Mock gather_constants to be overridden
        def gather_constants
          []
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

      # Mock decorate method to be overridden
      def decorate
        # Override in subclass
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
    # Store the last scope created for test access
    # (needed because decorate has void return type in Sorbet)
    attr_reader :last_scope

    def create_path(_constant)
      @last_scope = Scope.new
      yield @last_scope
      @last_scope
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
        compiler.decorate
        scope = root.last_scope

        getter = find_method(scope, "name")
        expect(getter).not_to be_nil
        expect(getter.return_type).to eq("::String")
      end

      it "generates predicate method with T::Boolean return type" do
        compiler.decorate
        scope = root.last_scope

        predicate = find_method(scope, "name?")
        expect(predicate).not_to be_nil
        expect(predicate.return_type).to eq("T::Boolean")
      end

      it "generates private setter method" do
        compiler.decorate
        scope = root.last_scope

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
        compiler.decorate
        scope = root.last_scope

        getter = find_method(scope, "email")
        expect(getter.return_type).to eq("T.nilable(::String)")
      end

      it "generates setter with nilable parameter type" do
        compiler.decorate
        scope = root.last_scope

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
        compiler.decorate
        scope = root.last_scope

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
        compiler.decorate
        scope = root.last_scope

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
        compiler.decorate
        scope = root.last_scope

        expect(find_method(scope, "result")).not_to be_nil
        expect(find_method(scope, "result?")).not_to be_nil
        expect(find_method(scope, "result=")).not_to be_nil
      end

      it "generates getter with correct return type" do
        compiler.decorate
        scope = root.last_scope

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
        compiler.decorate
        scope = root.last_scope

        expect(find_method(scope, "input")).not_to be_nil
        expect(find_method(scope, "output")).not_to be_nil
      end

      it "generates 6 methods total (3 per field)" do
        compiler.decorate
        scope = root.last_scope

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
        compiler.decorate

        expect(root.last_scope).to be_nil
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
        compiler.decorate
        scope = root.last_scope

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
        compiler.decorate
        scope = root.last_scope

        expect(find_method(scope, "parent_arg")).not_to be_nil
        expect(find_method(scope, "child_arg")).not_to be_nil
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
        compiler.decorate
        scope = root.last_scope

        getter = find_method(scope, "untyped_arg")
        expect(getter.return_type).to eq("T.untyped")
      end

      it "generates setter with T.untyped parameter type" do
        compiler.decorate
        scope = root.last_scope

        setter = find_method(scope, "untyped_arg=")
        expect(setter.parameters.first.type).to eq("T.untyped")
      end

      it "still generates predicate with T::Boolean" do
        compiler.decorate
        scope = root.last_scope

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
        compiler.decorate
        scope = root.last_scope

        getter = find_method(scope, "optional_untyped")
        # T.untyped already includes nil, so no wrapping
        expect(getter.return_type).to eq("T.untyped")
      end
    end

    context "when type is an unrecognized object" do
      let(:service_class) do
        klass = Class.new(Light::Services::Base) do
          def self.name
            "UnrecognizedTypeService"
          end
        end

        # Create a mock type that doesn't match Class/Module
        mock_type = Object.new
        mock_type.define_singleton_method(:to_s) { "CustomType::Unknown" }

        field = Light::Services::Settings::Field.new(:unknown_type, klass, field_type: :argument)
        field.instance_variable_set(:@type, mock_type)
        klass.own_arguments[:unknown_type] = field
        klass.instance_variable_set(:@arguments, nil)

        klass
      end

      it "returns T.untyped when type is unrecognized" do
        compiler.decorate
        scope = root.last_scope

        getter = find_method(scope, "unknown_type")
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
        compiler.decorate
        scope = root.last_scope

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
        compiler.decorate
        scope = root.last_scope

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
        compiler.decorate
        scope = root.last_scope

        getter = find_method(scope, "value")
        expect(getter.return_type).to eq("::String")
      end
    end

    context "with array containing multiple Ruby classes" do
      let(:service_class) do
        Class.new(Light::Services::Base) do
          def self.name
            "ArrayWithMultipleClassesService"
          end

          arg :value, type: [String, Integer]
        end
      end

      it "resolves to T.any union" do
        compiler.decorate
        scope = root.last_scope

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
        compiler.decorate
        scope = root.last_scope

        getter = find_method(scope, "mixed_unknown")
        expect(getter.return_type).to eq("T.any(::String, T.untyped, ::Integer)")
      end
    end
  end
end

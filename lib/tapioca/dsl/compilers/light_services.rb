# frozen_string_literal: true

return unless defined?(Tapioca::Dsl::Compiler)

module Tapioca
  module Dsl
    module Compilers
      # Tapioca DSL compiler for Light::Services
      #
      # Generates RBI signatures for methods automatically defined by the
      # `arg`/`argument` and `output` DSL macros in light-services.
      #
      # For each argument and output, three methods are generated:
      # - Getter: `def name` - returns the value
      # - Predicate: `def name?` - returns boolean
      # - Setter: `def name=` (private) - sets the value
      #
      # @example Service definition
      #   class CreateUser < Light::Services::Base
      #     arg :name, type: String
      #     arg :email, type: String, optional: true
      #     arg :role, type: [Symbol, String]
      #
      #     output :user, type: User
      #   end
      #
      # @example Generated RBI
      #   class CreateUser
      #     sig { returns(String) }
      #     def name; end
      #
      #     sig { returns(T::Boolean) }
      #     def name?; end
      #
      #     sig { returns(T.nilable(String)) }
      #     def email; end
      #
      #     sig { returns(T::Boolean) }
      #     def email?; end
      #
      #     sig { returns(T.any(Symbol, String)) }
      #     def role; end
      #
      #     sig { returns(T::Boolean) }
      #     def role?; end
      #
      #     sig { returns(User) }
      #     def user; end
      #
      #     sig { returns(T::Boolean) }
      #     def user?; end
      #
      #     private
      #
      #     sig { params(value: String).returns(String) }
      #     def name=(value); end
      #
      #     # ... other setters
      #   end
      class LightServices < Compiler
        extend T::Sig

        # Default type mappings for common dry-types to their underlying Ruby types
        DRY_TYPE_MAPPINGS = {
          "Types::String" => "::String",
          "Types::Strict::String" => "::String",
          "Types::Coercible::String" => "::String",
          "Types::Integer" => "::Integer",
          "Types::Strict::Integer" => "::Integer",
          "Types::Coercible::Integer" => "::Integer",
          "Types::Float" => "::Float",
          "Types::Strict::Float" => "::Float",
          "Types::Coercible::Float" => "::Float",
          "Types::Decimal" => "::BigDecimal",
          "Types::Strict::Decimal" => "::BigDecimal",
          "Types::Coercible::Decimal" => "::BigDecimal",
          "Types::Bool" => "T::Boolean",
          "Types::Strict::Bool" => "T::Boolean",
          "Types::True" => "::TrueClass",
          "Types::Strict::True" => "::TrueClass",
          "Types::False" => "::FalseClass",
          "Types::Strict::False" => "::FalseClass",
          "Types::Array" => "::Array",
          "Types::Strict::Array" => "::Array",
          "Types::Hash" => "::Hash",
          "Types::Strict::Hash" => "::Hash",
          "Types::Symbol" => "::Symbol",
          "Types::Strict::Symbol" => "::Symbol",
          "Types::Coercible::Symbol" => "::Symbol",
          "Types::Date" => "::Date",
          "Types::Strict::Date" => "::Date",
          "Types::DateTime" => "::DateTime",
          "Types::Strict::DateTime" => "::DateTime",
          "Types::Time" => "::Time",
          "Types::Strict::Time" => "::Time",
          "Types::Nil" => "::NilClass",
          "Types::Strict::Nil" => "::NilClass",
          "Types::Any" => "T.untyped",
        }.freeze

        ConstantType = type_member { { fixed: T.class_of(::Light::Services::Base) } }

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            all_classes.select do |klass|
              klass < ::Light::Services::Base && klass.name && klass != ::Light::Services::Base
            end
          end
        end

        sig { override.void }
        def decorate
          arguments = constant.arguments
          outputs = constant.outputs

          return if arguments.empty? && outputs.empty?

          root.create_path(constant) do |klass|
            # Generate argument methods
            arguments.each_value do |field|
              generate_field_methods(klass, field)
            end

            # Generate output methods
            outputs.each_value do |field|
              generate_field_methods(klass, field)
            end
          end
        end

        private

        sig { params(klass: RBI::Scope, field: ::Light::Services::Settings::Field).void }
        def generate_field_methods(klass, field)
          name = field.name.to_s
          ruby_type = resolve_type(field)
          return_type = field.optional ? as_nilable_type(ruby_type) : ruby_type

          # Getter
          klass.create_method(name, return_type: return_type)

          # Predicate
          klass.create_method("#{name}?", return_type: "T::Boolean")

          # Setter (private)
          klass.create_method(
            "#{name}=",
            parameters: [create_param("value", type: return_type)],
            return_type: return_type,
            visibility: RBI::Private.new,
          )
        end

        sig { params(field: ::Light::Services::Settings::Field).returns(String) }
        def resolve_type(field)
          type = field.instance_variable_get(:@type)
          return "T.untyped" unless type

          if type.is_a?(Array)
            resolve_array_type(type)
          elsif dry_type?(type)
            resolve_dry_type(type)
          elsif type.is_a?(Class) || type.is_a?(Module)
            ruby_type_for_class(type)
          else
            "T.untyped"
          end
        end

        sig { params(types: T::Array[T.untyped]).returns(String) }
        def resolve_array_type(types)
          resolved_types = types.map do |t|
            if t.is_a?(Class) || t.is_a?(Module)
              ruby_type_for_class(t)
            elsif dry_type?(t)
              resolve_dry_type(t)
            else
              "T.untyped"
            end
          end.uniq

          return resolved_types.first if resolved_types.size == 1

          # Check if this is a boolean type (TrueClass + FalseClass)
          if resolved_types.sort == ["::FalseClass", "::TrueClass"]
            "T::Boolean"
          else
            "T.any(#{resolved_types.join(', ')})"
          end
        end

        sig { params(klass: T.any(Class, Module)).returns(String) }
        def ruby_type_for_class(klass)
          name = klass.name
          return "T.untyped" unless name

          # Handle boolean types specially
          if klass == TrueClass
            "::TrueClass"
          elsif klass == FalseClass
            "::FalseClass"
          else
            "::#{name}"
          end
        end

        sig { params(type: T.untyped).returns(T::Boolean) }
        def dry_type?(type)
          return false unless defined?(Dry::Types::Type)

          type.is_a?(Dry::Types::Type)
        end

        sig { params(type: T.untyped).returns(String) }
        def resolve_dry_type(type)
          type_string = type.to_s

          # Direct mapping lookup
          return DRY_TYPE_MAPPINGS[type_string] if DRY_TYPE_MAPPINGS.key?(type_string)

          # Handle parameterized types: Types::Array.of(...) → Types::Array
          base_type = type_string.split(".").first
          return DRY_TYPE_MAPPINGS[base_type] if DRY_TYPE_MAPPINGS.key?(base_type)

          # Try to infer from primitive
          infer_from_primitive(type)
        end

        sig { params(type: T.untyped).returns(String) }
        def infer_from_primitive(type)
          return "T.untyped" unless type.respond_to?(:primitive)

          primitive = type.primitive
          return "T.untyped" unless primitive.is_a?(Class) || primitive.is_a?(Module)

          ruby_type_for_class(primitive)
        rescue StandardError
          "T.untyped"
        end

        sig { params(type: String).returns(String) }
        def as_nilable_type(type)
          # Don't double-wrap nilable types
          return type if type.start_with?("T.nilable(")
          return type if type == "T.untyped"

          "T.nilable(#{type})"
        end
      end
    end
  end
end

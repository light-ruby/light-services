# frozen_string_literal: true

# Unified settings class for arguments and outputs
module Light
  module Services
    module Settings
      class Field
        attr_reader :name, :default_exists, :default, :context, :optional

        def initialize(name, service_class, opts = {})
          @name = name
          @service_class = service_class
          @field_type = opts.delete(:field_type) || :argument

          @type = opts.delete(:type)
          @context = opts.delete(:context)
          @default_exists = opts.key?(:default)
          @default = opts.delete(:default)
          @optional = opts.delete(:optional)

          define_methods
        end

        # Validate and optionally coerce the value
        # Returns the (possibly coerced) value
        def validate_type!(value)
          return value unless @type

          if dry_type?(@type)
            coerce_and_validate_dry_type!(value)
          else
            validate_ruby_type!(value)
            value
          end
        end

        private

        # Check if the type is a dry-types type
        def dry_type?(type)
          return false unless defined?(Dry::Types::Type)

          type.is_a?(Dry::Types::Type)
        end

        # Validate and coerce value against dry-types
        # Returns the coerced value
        def coerce_and_validate_dry_type!(value)
          @type[value]
        rescue Dry::Types::ConstraintError, Dry::Types::CoercionError => e
          raise Light::Services::ArgTypeError,
                "#{@service_class} #{@field_type} `#{@name}` #{e.message}"
        end

        # Validate value against Ruby class types
        def validate_ruby_type!(value)
          return if [*@type].any? { |type| value.is_a?(type) }

          raise Light::Services::ArgTypeError, type_error_message(value)
        end

        def type_error_message(value)
          expected_types = [*@type].map(&:to_s).join(" or ")
          "#{@service_class} #{@field_type} `#{@name}` must be #{expected_types}, \" \\
            \"but got #{value.class} with value: #{value.inspect}"
        end

        def define_methods
          name = @name
          collection_instance_var = :"@#{@field_type}s"

          @service_class.define_method(@name) { instance_variable_get(collection_instance_var).get(name) }
          @service_class.define_method(:"#{@name}?") { !!instance_variable_get(collection_instance_var).get(name) }
          @service_class.define_method(:"#{@name}=") do |value|
            instance_variable_get(collection_instance_var).set(name, value)
          end
          @service_class.send(:private, "#{@name}=")
        end
      end

      # Aliases for backwards compatibility
      Argument = Field
      Output = Field
    end
  end
end

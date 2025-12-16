# frozen_string_literal: true

module Light
  module Services
    module Settings
      # Stores configuration for a single argument or output field.
      # Created automatically when using the `arg` or `output` DSL methods.
      class Field
        # @return [Symbol] the field name
        attr_reader :name

        # @return [Boolean] true if a default value was specified
        attr_reader :default_exists

        # @return [Object, Proc, nil] the default value or proc
        attr_reader :default

        # @return [Boolean, nil] true if this is a context argument
        attr_reader :context

        # @return [Boolean, nil] true if nil values are allowed
        attr_reader :optional

        # Initialize a new field definition.
        #
        # @param name [Symbol] the field name
        # @param service_class [Class] the service class this field belongs to
        # @param opts [Hash] field options
        # @option opts [Class, Array<Class>] :type type(s) to validate against
        # @option opts [Boolean] :optional whether nil is allowed
        # @option opts [Object, Proc] :default default value or proc
        # @option opts [Boolean] :context whether to pass to child services
        # @option opts [Symbol] :field_type :argument or :output
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

        # Validate a value against the field's type definition.
        # Supports Ruby class types, dry-types, and Sorbet runtime types.
        #
        # @param value [Object] the value to validate
        # @return [Object] the value (possibly coerced by dry-types)
        # @raise [ArgTypeError] if the value doesn't match the expected type
        def validate_type!(value)
          return value unless @type

          if dry_type?(@type)
            coerce_and_validate_dry_type!(value)
          elsif sorbet_type?(@type) || (sorbet_available? && plain_class_type?(@type))
            validate_sorbet_type!(value)
          else
            validate_ruby_type!(value)
            value
          end
        end

        private

        # Check if sorbet-runtime is available
        def sorbet_available?
          defined?(T::Types::Base)
        end

        # Check if the type is a plain Ruby class (not dry-types or Sorbet type)
        def plain_class_type?(type)
          type.is_a?(Class) || type.is_a?(Module)
        end

        # Check if the type is a dry-types type
        def dry_type?(type)
          return false unless defined?(Dry::Types::Type)

          type.is_a?(Dry::Types::Type)
        end

        # Check if the type is a Sorbet runtime type
        def sorbet_type?(type)
          return false unless defined?(T::Types::Base)

          type.is_a?(T::Types::Base)
        end

        # Validate and coerce value against dry-types
        # Returns the coerced value
        def coerce_and_validate_dry_type!(value)
          @type[value]
        rescue Dry::Types::ConstraintError, Dry::Types::CoercionError => e
          raise Light::Services::ArgTypeError,
                "#{@service_class} #{@field_type} `#{@name}` #{e.message}"
        end

        # Validate value against Sorbet runtime types
        # Note: Sorbet types only validate, they do not coerce values
        # Automatically coerces plain Ruby classes to Sorbet types when needed
        # @return [Object] the original value if valid
        # @raise [ArgTypeError] if the value doesn't match the expected type
        def validate_sorbet_type!(value)
          sorbet_type = sorbet_type?(@type) ? @type : T::Utils.coerce(@type)
          return value if sorbet_type.valid?(value)

          raise Light::Services::ArgTypeError,
                "#{@service_class} #{@field_type} `#{@name}` expected #{sorbet_type.name}, " \
                "but got #{value.class} with value: #{value.inspect}"
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

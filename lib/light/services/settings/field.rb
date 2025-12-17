# frozen_string_literal: true
# typed: strict

require "sorbet-runtime"

module Light
  module Services
    module Settings
      # Stores configuration for a single argument or output field.
      # Created automatically when using the `arg` or `output` DSL methods.
      class Field
        extend T::Sig

        # @return [Symbol] the field name
        sig { returns(Symbol) }
        attr_reader :name

        # @return [Boolean] true if a default value was specified
        sig { returns(T::Boolean) }
        attr_reader :default_exists

        # @return [Object, Proc, nil] the default value or proc
        sig { returns(T.untyped) }
        attr_reader :default

        # @return [Boolean, nil] true if this is a context argument
        sig { returns(T.nilable(T::Boolean)) }
        attr_reader :context

        # @return [Boolean, nil] true if nil values are allowed
        sig { returns(T.nilable(T::Boolean)) }
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
        sig { params(name: Symbol, service_class: T.untyped, opts: T::Hash[Symbol, T.untyped]).void }
        def initialize(name, service_class, opts = {}) # rubocop:disable Metrics/AbcSize
          @name = T.let(name, Symbol)
          @service_class = T.let(service_class, T.untyped)
          @field_type = T.let(opts.delete(:field_type) || :argument, Symbol)

          @type = T.let(opts.delete(:type), T.untyped)
          @context = T.let(opts.delete(:context), T.nilable(T::Boolean))
          @default_exists = T.let(opts.key?(:default), T::Boolean)
          @default = T.let(opts.delete(:default), T.untyped)
          @optional = T.let(opts.delete(:optional), T.nilable(T::Boolean))

          define_methods
        end

        # Validate a value against the field's type definition.
        # Supports Ruby class types and Sorbet runtime types.
        #
        # @param value [Object] the value to validate
        # @return [Object] the validated value
        # @raise [ArgTypeError] if the value doesn't match the expected type
        sig { params(value: T.untyped).returns(T.untyped) }
        def validate_type!(value)
          return value unless @type

          if sorbet_type?(@type) || (sorbet_available? && plain_class_type?(@type))
            validate_sorbet_type!(value)
          else
            validate_ruby_type!(value)
            value
          end
        end

        private

        # Check if sorbet-runtime is available
        sig { returns(T::Boolean) }
        def sorbet_available?
          defined?(T::Types::Base) ? true : false
        end

        # Check if the type is a plain Ruby class (not a Sorbet type)
        sig { params(type: T.untyped).returns(T::Boolean) }
        def plain_class_type?(type)
          type.is_a?(Class) || type.is_a?(Module)
        end

        # Check if the type is a Sorbet runtime type
        sig { params(type: T.untyped).returns(T::Boolean) }
        def sorbet_type?(type)
          return false unless defined?(T::Types::Base)

          type.is_a?(T::Types::Base)
        end

        # Validate value against Sorbet runtime types
        # Note: Sorbet types only validate, they do not coerce values
        # Automatically coerces plain Ruby classes to Sorbet types when needed
        # @return [Object] the original value if valid
        # @raise [ArgTypeError] if the value doesn't match the expected type
        sig { params(value: T.untyped).returns(T.untyped) }
        def validate_sorbet_type!(value)
          sorbet_type = sorbet_type?(@type) ? @type : T::Utils.coerce(@type)
          return value if sorbet_type.valid?(value)

          raise Light::Services::ArgTypeError,
                "#{@service_class} #{@field_type} `#{@name}` expected #{sorbet_type.name}, " \
                "but got #{value.class} with value: #{value.inspect}"
        end

        # Validate value against Ruby class types
        sig { params(value: T.untyped).void }
        def validate_ruby_type!(value)
          return if [*@type].any? { |type| value.is_a?(type) }

          raise Light::Services::ArgTypeError, type_error_message(value)
        end

        sig { params(value: T.untyped).returns(String) }
        def type_error_message(value)
          expected_types = [*@type].map(&:to_s).join(" or ")
          "#{@service_class} #{@field_type} `#{@name}` must be #{expected_types}, \" \\
            \"but got #{value.class} with value: #{value.inspect}"
        end

        sig { void }
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

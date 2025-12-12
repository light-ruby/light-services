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

        def validate_type!(value)
          return if !@type || [*@type].any? { |type| value.is_a?(type) }

          raise Light::Services::ArgTypeError, type_error_message(value)
        end

        private

        def type_error_message(value)
          "#{@service_class} #{@field_type} `#{@name}` must be " \
            "a #{[*@type].join(', ')} (currently: #{value.class})"
        end

        def define_methods
          name = @name
          collection_ivar = :"@#{@field_type}s"

          @service_class.define_method(@name) { instance_variable_get(collection_ivar).get(name) }
          @service_class.define_method(:"#{@name}?") { !!instance_variable_get(collection_ivar).get(name) }
          @service_class.define_method(:"#{@name}=") { |value| instance_variable_get(collection_ivar).set(name, value) }
          @service_class.send(:private, "#{@name}=")
        end
      end

      # Aliases for backwards compatibility
      Argument = Field
      Output = Field
    end
  end
end

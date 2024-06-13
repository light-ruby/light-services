# frozen_string_literal: true

# This class defines items for argument
module Light
  module Services
    module Items
      class Argument
        # Getters
        attr_reader :name, :default_exists, :default, :context, :optional, :arg_types_cache

        def initialize(name, service_class, opts = {})
          @name = name
          @service_class = service_class

          @type = opts.delete(:type)
          @context = opts.delete(:context)
          @default_exists = opts.key?(:default)
          @default = opts.delete(:default)
          @optional = opts.delete(:optional)

          define_methods
        end

        def validate_type!(value)
          return if !@type || [*@type].any? do |type|
            case type
            when :boolean
              value.is_a?(TrueClass) || value.is_a?(FalseClass)
            when Symbol
              class_to_symbol(value.class) == type
            else
              value.is_a?(type)
            end
          end

          raise Light::Services::ArgTypeError, "#{@service_class} argument `#{name}` must be " \
                                               "a #{[*@type].join(', ')} (currently: #{value.class})"
        end

        private

        def class_to_symbol(klass)
          klass
            .name
            .gsub("::", "/")
            .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
            .gsub(/([a-z\d])([A-Z])/, '\1_\2')
            .tr("-", "_")
            .downcase
            .to_sym
        end

        def define_methods
          name = @name

          @service_class.define_method(@name) { @arguments.get(name) }
          @service_class.define_method(:"#{@name}?") { !!@arguments.get(name) }
          @service_class.define_method(:"#{@name}=") { |value| @arguments.set(name, value) }
          @service_class.send(:private, "#{@name}=")
        end
      end
    end
  end
end

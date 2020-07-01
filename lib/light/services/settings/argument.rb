# frozen_string_literal: true

# This class defines settings for argument
module Light
  module Services
    module Settings
      class Argument
        # Getters
        attr_reader :name, :default_exists, :default, :context, :optional

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

        def valid_type?(value)
          return if !@type || [*@type].any? do |type|
            if type == :boolean
              value.is_a?(TrueClass) || value.is_a?(FalseClass)
            else
              value.is_a?(type)
            end
          end

          raise Light::Services::ArgTypeError, "#{@service_class} argument `#{name}` must be " \
                                               "a #{[*@type].join(', ')} (currently: #{value.class})"
        end

        private

        def define_methods
          name = @name

          @service_class.define_method(@name) { @arguments.get(name) }
          @service_class.define_method("#{@name}?") { !!@arguments.get(name) } # rubocop:disable Style/DoubleNegation
          @service_class.define_method("#{@name}=") { |value| @arguments.set(name, value) }
          @service_class.send(:private, "#{@name}=")
        end
      end
    end
  end
end

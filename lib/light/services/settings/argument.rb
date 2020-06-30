# frozen_string_literal: true

module Light
  module Services
    module Settings
      class Argument
        # Getters
        attr_reader :name, :default_exists, :default, :context, :optional

        def initialize(name, klass, opts = {})
          @name = name
          @klass = klass

          @type = opts.delete(:type)
          @context = opts.delete(:context)
          @default_exists = opts.key?(:default)
          @default = opts.delete(:default)
          @optional = opts.delete(:optional)

          define_methods
        end

        def valid_type?(value)
          return unless @type

          valid = [*@type].any? do |type|
            case type
            when :boolean
              value.is_a?(TrueClass) || value.is_a?(FalseClass)
            else
              value.is_a?(type)
            end
          end

          return if valid

          raise Light::Services::ArgTypeError, "`#{@klass}` argument `#{name}` must be a #{[*@type].join(', ')} (currently: #{value.class})"
        end

        private

        # TODO: Refactor __method__
        def define_methods
          @klass.define_method @name do
            @arguments.get(__method__)
          end

          @klass.define_method "#{@name}?" do
            !!@arguments.get(__method__[0..-2].to_sym) # rubocop:disable Style/DoubleNegation
          end

          @klass.define_method "#{@name}=" do |value|
            @arguments.set(__method__[0..-2].to_sym, value)
          end

          @klass.send :private, "#{@name}="
        end
      end
    end
  end
end

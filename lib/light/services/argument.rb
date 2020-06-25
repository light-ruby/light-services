# frozen_string_literal: true

module Light
  module Services
    class Argument
      # Getters
      attr_reader :name, :default_exists, :default, :optional

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

        raise Light::Services::Error, "`#{@klass}` argument `#{name}` must be a #{[*@type].join(', ')}"
      end

      private

      # TODO: Refactor __method__
      def define_methods
        @klass.define_method @name do
          @arguments[__method__]
        end

        @klass.define_method "#{@name}?" do
          !!@arguments[__method__[0..-2].to_sym]
        end

        @klass.define_method "#{@name}=" do |val|
          @arguments[__method__[0..-2].to_sym] = val
        end

        @klass.send :private, "#{@name}="
      end
    end
  end
end

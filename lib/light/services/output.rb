# frozen_string_literal: true

module Light
  module Services
    class Output
      # Getters
      attr_reader :name, :default_exists, :default

      def initialize(name, klass, opts = {})
        @name = name
        @klass = klass

        @default_exists = opts.key?(:default)
        @default = opts.delete(:default)

        define_methods
      end

      private

      # TODO: Refactor __method__
      def define_methods
        @klass.define_method @name do
          @outputs[__method__]
        end

        @klass.define_method "#{@name}?" do
          !!@outputs[__method__[0..-2].to_sym]
        end

        @klass.define_method "#{@name}=" do |val|
          @outputs[__method__[0..-2].to_sym] = val
        end

        @klass.send :private, "#{@name}="
      end
    end
  end
end

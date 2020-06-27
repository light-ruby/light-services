# frozen_string_literal: true

module Light
  module Services
    module Settings
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
            @outputs.get(__method__)
          end

          @klass.define_method "#{@name}?" do
            !!@outputs.get(__method__[0..-2].to_sym)
          end

          @klass.define_method "#{@name}=" do |value|
            @outputs.set(__method__[0..-2].to_sym, value)
          end

          @klass.send :private, "#{@name}="
        end
      end
    end
  end
end

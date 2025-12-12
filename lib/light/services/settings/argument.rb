# frozen_string_literal: true

require "light/services/settings/type_validatable"

# This class defines settings for argument
module Light
  module Services
    module Settings
      class Argument
        include TypeValidatable

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

        private

        def setting_type
          "argument"
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

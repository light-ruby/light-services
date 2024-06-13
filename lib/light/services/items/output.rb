# frozen_string_literal: true

# This class defines items for output
module Light
  module Services
    module Items
      class Output
        # Getters
        attr_reader :name, :default_exists, :default

        def initialize(name, service_class, opts = {})
          @name = name
          @service_class = service_class

          @default_exists = opts.key?(:default)
          @default = opts.delete(:default)

          define_methods
        end

        private

        def define_methods
          name = @name

          @service_class.define_method(@name) { @outputs.get(name) }
          @service_class.define_method(:"#{@name}?") { !!@outputs.get(name) }
          @service_class.define_method(:"#{@name}=") { |value| @outputs.set(name, value) }
          @service_class.send(:private, "#{@name}=")
        end
      end
    end
  end
end

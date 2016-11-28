module Light
  module Service
    module Parameters
      def self.included(base)
        base.extend ClassMethods
        base.class_eval do
          class << self
            attr_accessor :parameters
            attr_accessor :outputs
          end
        end
      end

      private

      def initialize_params
        params = {}

        (self.class.parameters || []).each do |options|
          # Skip or raise exception if parameter not exist
          unless args.key?(options[:name])
            if options[:required]
              raise Light::Service::ParamRequired, "Parameter \"#{options[:name]}\" is required"
            else
              next
            end
          end

          # Load parameter value
          param = args[options[:name]]

          # Check type of parameter
          if options[:type] && !param.is_a?(options[:type])
            raise Light::Service::ParamType, "Type of \"#{options[:name]}\" must be \"#{options[:type]}\""
          end

          # Create instance variable and getter
          params[options[:name]] = param

          define_singleton_method options[:name] do
            params[options[:name]]
          end

          define_singleton_method "#{options[:name]}=" do |value|
            params[options[:name]] = value
          end
        end

        params
      end

      def initialize_outputs
        outputs = {}

        (self.class.outputs || []).each do |options|
          outputs[options[:name]] = options[:value]

          define_singleton_method options[:name] do
            outputs[options[:name]]
          end

          define_singleton_method "#{options[:name]}=" do |value|
            outputs[options[:name]] = value
          end
        end

        outputs
      end

      module ClassMethods
        def param(name, options = {})
          self.parameters ||= []
          self.parameters << {
            name:     name,
            required: options.key?(:required) ? options[:required] : true,
            public:   options.key?(:private)  ? options[:private] : false,
            type:     options[:type] || nil,
          }
        end

        def output(name, value = nil, options = {})
          self.outputs ||= []
          self.outputs << {
            name:   name,
            value:  value,
            public: options.key?(:private) ? options[:private] : false
          }
        end
      end
    end
  end
end

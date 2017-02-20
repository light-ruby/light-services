module Light
  module Services
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

      def parameters
        @parameters_storage.to_hash
      end

      def outputs
        @outputs_storage.to_hash
      end

      private

      def initialize_params
        @parameters_storage = Light::Services::Variables.new

        (self.class.parameters || []).each do |options|
          # Skip or raise exception if parameter not exist
          unless args.key?(options[:name])
            next unless options[:required]
            next if options[:allow_nil]
            raise Light::Services::ParamRequired, "Parameter \"#{options[:name]}\" is required"
          end

          # Load parameter value
          value = args[options[:name]]

          # Check type of parameter
          wrong_type    = options[:type] && !options[:type].include?(value.class)
          not_allow_nil = !options[:allow_nil] || (options[:allow_nil] && !value.nil?)

          if wrong_type && not_allow_nil
            raise Light::Services::ParamType, "Type of \"#{options[:name]}\" must be \"#{options[:type]}\""
          end

          # Create instance variable and getter
          @parameters_storage.add(options[:name], value)

          define_singleton_method options[:name] do
            @parameters_storage.get(options[:name])
          end

          define_singleton_method "#{options[:name]}=" do |val|
            @parameters_storage.add(options[:name], val)
          end
        end

        @parameters_storage
      end

      def initialize_outputs
        @outputs_storage = Light::Services::Variables.new

        (self.class.outputs || []).each do |options|
          @outputs_storage.add(options[:name], options[:value])

          define_singleton_method options[:name] do
            @outputs_storage.get(options[:name])
          end

          define_singleton_method "#{options[:name]}=" do |value|
            @outputs_storage.add(options[:name], value)
          end
        end

        @outputs_storage
      end

      module ClassMethods
        def param(name, options = {})
          self.parameters ||= []
          self.parameters << {
            name:      name,
            required:  options.fetch(:required, true),
            public:    options.fetch(:private, false),
            type:      [*options[:type]].compact,
            allow_nil: options.fetch(:allow_nil, false)
          }
        end

        def output(name, value = nil, options = {})
          self.outputs ||= []
          self.outputs << {
            name:   name,
            value:  value,
            public: options.fetch(:private, false)
          }
        end
      end
    end
  end
end

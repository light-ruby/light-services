# frozen_string_literal: true

module Light
  module Services
    module Parameters
      def self.included(base)
        base.extend ClassMethods
        base.class_eval do
          class << self
            attr_accessor :parameters
          end
        end
      end

      # Getters
      attr_reader :parameters

      private

      # Setters
      attr_writer :parameters

      def initialize_params
        self.parameters = {}

        (self.class.parameters || []).each do |options|
          validate_parameter(options)
          store_parameter(options)
        end

        generate_parameters_methods
      end

      def validate_parameter(options)
        if parameter_required?(options)
          raise Light::Services::ParamRequired, "Parameter \"#{options[:name]}\" is required"
        end

        return unless parameter_wrong_type?(options)

        raise Light::Services::ParamType, "Type of \"#{options[:name]}\" must be \"#{options[:type]}\""
      end

      def parameter_required?(options)
        !args.key?(options[:name]) && options[:required] && !options[:allow_nil]
      end

      def parameter_wrong_type?(options)
        value = args[options[:name]]

        wrong_type    = options[:type] && !options[:type].include?(value.class)
        not_allow_nil = !options[:allow_nil] || (options[:allow_nil] && !value.nil?)

        wrong_type && not_allow_nil
      end

      def store_parameter(options)
        parameter_name = options[:name]
        parameter_value = args[parameter_name]

        parameters[parameter_name] = parameter_value
      end

      def generate_parameters_methods
        parameters.keys.each do |parameter_name|
          define_singleton_method parameter_name do
            parameters[parameter_name]
          end

          define_singleton_method "#{parameter_name}=" do |value|
            parameters[parameter_name] = value
          end
        end
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
      end
    end
  end
end

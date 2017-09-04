# frozen_string_literal: true

module Light
  module Services
    module Outputs
      def self.included(base)
        base.extend ClassMethods
        base.class_eval do
          class << self
            attr_accessor :outputs
          end
        end
      end

      # Getters
      attr_reader :outputs

      private

      # Setters
      attr_writer :outputs

      def initialize_outputs
        self.outputs = {}

        all_outputs.each do |options|
          store_output(options)
        end

        generate_outputs_methods
      end

      def all_outputs
        return @_all_outputs if defined?(@_all_outputs)
        @_all_outputs = self.class.ancestors.select { |klass| klass.ancestors.include?(::Light::Services::Base) }
                            .map(&:outputs).compact.flatten.uniq
      end

      def store_output(options)
        output_name  = options[:name]
        output_value = options[:value]

        outputs[output_name] = output_value
      end

      def generate_outputs_methods
        outputs.keys.each do |output_name|
          define_singleton_method output_name do
            outputs[output_name]
          end

          define_singleton_method "#{output_name}=" do |value|
            outputs[output_name] = value
          end
        end
      end

      module ClassMethods
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

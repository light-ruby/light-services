# frozen_string_literal: true

require_relative "../constants"

module Light
  module Services
    module Dsl
      # Shared validation logic for DSL modules
      module Validation
        # Validate that the name is a symbol
        #
        # @param name [Object] the name to validate
        # @param field_type [Symbol] the type of field (:argument, :output, :step)
        # @param service_class [Class] the service class for error messages
        def self.validate_symbol_name!(name, field_type, service_class)
          return if name.is_a?(Symbol)

          raise Light::Services::InvalidNameError,
                "#{field_type.to_s.capitalize} name must be a Symbol, got #{name.class} (#{name.inspect}) in #{service_class}"
        end

        # Validate that the name is not a reserved word
        #
        # @param name [Symbol] the name to validate
        # @param field_type [Symbol] the type of field (:argument, :output, :step)
        # @param service_class [Class] the service class for error messages
        def self.validate_reserved_name!(name, field_type, service_class)
          return unless ReservedNames::ALL.include?(name.to_sym)

          raise Light::Services::ReservedNameError,
                "Cannot use `#{name}` as #{field_type} name in #{service_class} - " \
                "it is a reserved word that conflicts with gem methods"
        end

        # Validate that the name doesn't conflict with other defined names
        #
        # @param name [Symbol] the name to validate
        # @param field_type [Symbol] the type of field being defined (:argument, :output, :step)
        # @param service_class [Class] the service class to check for conflicts
        def self.validate_name_conflicts!(name, field_type, service_class)
          name_sym = name.to_sym

          case field_type
          when :argument
            validate_argument_conflicts!(name_sym, service_class)
          when :output
            validate_output_conflicts!(name_sym, service_class)
          when :step
            validate_step_conflicts!(name_sym, service_class)
          end
        end

        # Validate argument name doesn't conflict with outputs or steps
        def self.validate_argument_conflicts!(name_sym, service_class)
          # Check against existing outputs
          if has_output?(name_sym, service_class)
            raise Light::Services::ReservedNameError,
                  "Cannot use `#{name_sym}` as argument name in #{service_class} - " \
                  "it is already defined as an output"
          end

          # Check against existing steps
          if has_step?(name_sym, service_class)
            raise Light::Services::ReservedNameError,
                  "Cannot use `#{name_sym}` as argument name in #{service_class} - " \
                  "it is already defined as a step"
          end
        end

        # Validate output name doesn't conflict with arguments or steps
        def self.validate_output_conflicts!(name_sym, service_class)
          # Check against existing arguments
          if has_argument?(name_sym, service_class)
            raise Light::Services::ReservedNameError,
                  "Cannot use `#{name_sym}` as output name in #{service_class} - " \
                  "it is already defined as an argument"
          end

          # Check against existing steps
          if has_step?(name_sym, service_class)
            raise Light::Services::ReservedNameError,
                  "Cannot use `#{name_sym}` as output name in #{service_class} - " \
                  "it is already defined as a step"
          end
        end

        # Validate step name doesn't conflict with arguments or outputs
        def self.validate_step_conflicts!(name_sym, service_class)
          # Check against existing arguments
          if has_argument?(name_sym, service_class)
            raise Light::Services::ReservedNameError,
                  "Cannot use `#{name_sym}` as step name in #{service_class} - " \
                  "it is already defined as an argument"
          end

          # Check against existing outputs
          if has_output?(name_sym, service_class)
            raise Light::Services::ReservedNameError,
                  "Cannot use `#{name_sym}` as step name in #{service_class} - " \
                  "it is already defined as an output"
          end
        end

        # Check if a name is already defined as an argument
        def self.has_argument?(name_sym, service_class)
          # Check own_arguments (current class)
          (service_class.respond_to?(:own_arguments) && service_class.own_arguments.key?(name_sym)) ||
            # Check inherited arguments
            (service_class.superclass.respond_to?(:arguments) && service_class.superclass.arguments.key?(name_sym))
        end

        # Check if a name is already defined as an output
        def self.has_output?(name_sym, service_class)
          # Check own_outputs (current class)
          (service_class.respond_to?(:own_outputs) && service_class.own_outputs.key?(name_sym)) ||
            # Check inherited outputs
            (service_class.superclass.respond_to?(:outputs) && service_class.superclass.outputs.key?(name_sym))
        end

        # Check if a name is already defined as a step
        def self.has_step?(name_sym, service_class)
          # Check step_operations (current class) for non-removed steps
          (service_class.respond_to?(:step_operations) &&
           service_class.step_operations.any? { |op| op[:name] == name_sym && op[:action] != :remove }) ||
            # Check inherited steps
            (service_class.superclass.respond_to?(:steps) && service_class.superclass.steps.key?(name_sym))
        end
      end
    end
  end
end

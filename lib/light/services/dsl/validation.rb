# typed: strict
# frozen_string_literal: true

require_relative "../constants"
require "sorbet-runtime"

module Light
  module Services
    module Dsl
      # Shared validation logic for DSL modules
      module Validation # rubocop:disable Metrics/ModuleLength
        extend T::Sig

        # Validate that the name is a symbol
        #
        # @param name [Object] the name to validate
        # @param field_type [Symbol] the type of field (:argument, :output, :step)
        # @param service_class [Class] the service class for error messages
        sig { params(name: T.untyped, field_type: Symbol, service_class: T.untyped).void }
        def self.validate_symbol_name!(name, field_type, service_class)
          return if name.is_a?(Symbol)

          raise Light::Services::InvalidNameError,
                "#{field_type.to_s.capitalize} name must be a Symbol, " \
                "got #{name.class} (#{name.inspect}) in #{service_class}"
        end

        # Validate that the name is not a reserved word
        #
        # @param name [Symbol] the name to validate
        # @param field_type [Symbol] the type of field (:argument, :output, :step)
        # @param service_class [Class] the service class for error messages
        sig { params(name: Symbol, field_type: Symbol, service_class: T.untyped).void }
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
        sig { params(name: Symbol, field_type: Symbol, service_class: T.untyped).void }
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
        sig { params(name_sym: Symbol, service_class: T.untyped).void }
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
        sig { params(name_sym: Symbol, service_class: T.untyped).void }
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
        sig { params(name_sym: Symbol, service_class: T.untyped).void }
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
        sig { params(name_sym: Symbol, service_class: T.untyped).returns(T::Boolean) }
        def self.has_argument?(name_sym, service_class)
          # Check own_arguments (current class)
          (service_class.respond_to?(:own_arguments) && service_class.own_arguments.key?(name_sym)) ||
            # Check inherited arguments
            (service_class.superclass.respond_to?(:arguments) && service_class.superclass.arguments.key?(name_sym))
        end

        # Check if a name is already defined as an output
        sig { params(name_sym: Symbol, service_class: T.untyped).returns(T::Boolean) }
        def self.has_output?(name_sym, service_class)
          # Check own_outputs (current class)
          (service_class.respond_to?(:own_outputs) && service_class.own_outputs.key?(name_sym)) ||
            # Check inherited outputs
            (service_class.superclass.respond_to?(:outputs) && service_class.superclass.outputs.key?(name_sym))
        end

        # Check if a name is already defined as a step
        sig { params(name_sym: Symbol, service_class: T.untyped).returns(T::Boolean) }
        def self.has_step?(name_sym, service_class)
          # Check step_operations (current class) for non-removed steps
          # Step operations now use typed StepOperation classes
          (service_class.respond_to?(:step_operations) &&
           service_class.step_operations.any? do |op|
             op.name == name_sym && !op.is_a?(Settings::RemoveStepOperation)
           end) ||
            # Check inherited steps
            (service_class.superclass.respond_to?(:steps) && service_class.superclass.steps.key?(name_sym))
        end

        # Validate that the type option is provided when require_type is enabled
        #
        # @param name [Symbol] the field name
        # @param field_type [Symbol] the type of field (:argument, :output)
        # @param service_class [Class] the service class for error messages
        # @param opts [Hash] the options hash to check for type
        sig { params(name: Symbol, field_type: Symbol, service_class: T.untyped, opts: T::Hash[Symbol, T.untyped]).void }
        def self.validate_type_required!(name, field_type, service_class, opts)
          return if opts.key?(:type)
          return unless require_type_enabled_for?(field_type, service_class)

          config_name = field_type == :argument ? "require_arg_type" : "require_output_type"
          raise Light::Services::MissingTypeError,
                "#{field_type.to_s.capitalize} `#{name}` in #{service_class} must have a type specified " \
                "(#{config_name} is enabled)"
        end

        # Check if require_type is enabled for the given field type and service class
        #
        # @param field_type [Symbol] the type of field (:argument, :output)
        # @param service_class [Class] the service class to check
        # @return [Boolean] whether type is required for the field type
        sig { params(field_type: Symbol, service_class: T.untyped).returns(T::Boolean) }
        def self.require_type_enabled_for?(field_type, service_class)
          config_key = field_type == :argument ? :require_arg_type : :require_output_type

          # Check class-level config in the inheritance chain, then fall back to global config
          klass = service_class
          while klass.respond_to?(:class_config)
            class_config = klass.class_config

            # Check specific config first (require_arg_type or require_output_type)
            return class_config[config_key] if class_config&.key?(config_key)

            # Check convenience config (require_type) for backward compatibility
            return class_config[:require_type] if class_config&.key?(:require_type)

            klass = klass.superclass
          end

          Light::Services.config.public_send(config_key)
        end
      end
    end
  end
end

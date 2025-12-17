# frozen_string_literal: true
# typed: strict

require "sorbet-runtime"

module Light
  module Services
    # Collection type constants
    module CollectionTypes
      extend T::Sig

      ARGUMENTS = T.let(:arguments, Symbol)
      OUTPUTS = T.let(:outputs, Symbol)

      ALL = T.let([ARGUMENTS, OUTPUTS].freeze, T::Array[Symbol])
    end

    # Field type constants
    module FieldTypes
      extend T::Sig

      ARGUMENT = T.let(:argument, Symbol)
      OUTPUT = T.let(:output, Symbol)

      ALL = T.let([ARGUMENT, OUTPUT].freeze, T::Array[Symbol])
    end

    # Reserved names that cannot be used for arguments, outputs, or steps
    # These names would conflict with existing gem methods
    module ReservedNames
      extend T::Sig

      # Instance methods from Base class and concerns
      BASE_METHODS = T.let([
        :outputs,
        :arguments,
        :errors,
        :warnings,
        :success?,
        :failed?,
        :errors?,
        :warnings?,
        :stop!,
        :stopped?,
        :stop_immediately!,
        :done!,
        :done?,
        :call,
        :run_callbacks,
      ].freeze, T::Array[Symbol])

      # Class methods that could conflict
      CLASS_METHODS = T.let([
        :config,
        :run,
        :run!,
        :with,
        :arg,
        :remove_arg,
        :output,
        :remove_output,
        :step,
        :remove_step,
        :steps,
        :outputs,
        :arguments,
      ].freeze, T::Array[Symbol])

      # Callback method names
      CALLBACK_METHODS = T.let([
        :before_step_run,
        :after_step_run,
        :around_step_run,
        :on_step_success,
        :on_step_failure,
        :on_step_crash,
        :before_service_run,
        :after_service_run,
        :around_service_run,
        :on_service_success,
        :on_service_failure,
      ].freeze, T::Array[Symbol])

      # Ruby reserved words and common Object methods
      RUBY_RESERVED = T.let([
        :initialize,
        :class,
        :object_id,
        :send,
        :__send__,
        :public_send,
        :respond_to?,
        :method,
        :methods,
        :instance_variable_get,
        :instance_variable_set,
        :instance_variables,
        :extend,
        :include,
        :new,
        :allocate,
        :superclass,
      ].freeze, T::Array[Symbol])

      # All reserved names combined (used for validation)
      ALL = T.let((BASE_METHODS + CALLBACK_METHODS + RUBY_RESERVED).uniq.freeze, T::Array[Symbol])
    end
  end
end

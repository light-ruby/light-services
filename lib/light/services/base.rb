# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "light/services/constants"
require "light/services/message"
require "light/services/messages"
require "light/services/base_with_context"

require "light/services/settings/step"
require "light/services/settings/step_operation"
require "light/services/settings/field"

require "light/services/collection"

require "light/services/dsl/arguments_dsl"
require "light/services/dsl/outputs_dsl"
require "light/services/dsl/steps_dsl"

# Base class for all service objects
module Light
  module Services
    # Base class for building service objects with arguments, outputs, and steps.
    #
    # @example Basic service
    #   class CreateUser < Light::Services::Base
    #     arg :name, type: String
    #     arg :email, type: String
    #
    #     output :user, type: User
    #
    #     step :create_user
    #
    #     private
    #
    #     def create_user
    #       self.user = User.create!(name: name, email: email)
    #     end
    #   end
    #
    #   result = CreateUser.run(name: "John", email: "john@example.com")
    #   result.success? # => true
    #   result.user     # => #<User id: 1, name: "John">
    # rubocop:disable Metrics/ClassLength
    class Base
      extend T::Sig
      extend CallbackDsl
      include Callbacks
      include Dsl::ArgumentsDsl
      include Dsl::OutputsDsl
      include Dsl::StepsDsl

      # @return [Collection::Base] collection of output values
      sig { returns(Collection::Base) }
      attr_reader :outputs

      # @return [Collection::Base] collection of argument values
      sig { returns(Collection::Base) }
      attr_reader :arguments

      # @return [Messages] collection of error messages
      sig { returns(Messages) }
      attr_reader :errors

      # @return [Messages] collection of warning messages
      sig { returns(Messages) }
      attr_reader :warnings

      # Initialize a new service instance.
      #
      # @param args [Hash] arguments to pass to the service
      # @param config [Hash] runtime configuration overrides
      # @param parent_service [Base, nil] parent service for nested calls
      sig { params(args: T::Hash[Symbol, T.untyped], config: T::Hash[Symbol, T.untyped], parent_service: T.nilable(Base)).void }
      def initialize(args = {}, config = {}, parent_service = nil) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        @config = T.let(
          Light::Services.config.merge(self.class.class_config || {}).merge(config),
          T::Hash[Symbol, T.untyped],
        )
        @parent_service = T.let(parent_service, T.nilable(Base))

        @outputs = T.let(Collection::Base.new(self, CollectionTypes::OUTPUTS), Collection::Base)
        @arguments = T.let(Collection::Base.new(self, CollectionTypes::ARGUMENTS, args.dup), Collection::Base)

        @stopped = T.let(false, T::Boolean)
        @launched_steps = T.let([], T::Array[Symbol])
        @cached_steps = T.let(nil, T.nilable(T::Hash[Symbol, Settings::Step]))

        @errors = T.let(
          Messages.new(
            break_on_add: @config[:break_on_error],
            raise_on_add: @config[:raise_on_error],
            rollback_on_add: @config[:use_transactions] && @config[:rollback_on_error],
          ),
          Messages,
        )

        @warnings = T.let(
          Messages.new(
            break_on_add: @config[:break_on_warning],
            raise_on_add: @config[:raise_on_warning],
            rollback_on_add: @config[:use_transactions] && @config[:rollback_on_warning],
          ),
          Messages,
        )
      end

      # Check if the service completed without errors.
      #
      # @return [Boolean] true if no errors were added
      sig { returns(T::Boolean) }
      def success?
        !errors?
      end
      alias successful? success?

      # Check if the service completed with errors.
      #
      # @return [Boolean] true if any errors were added
      sig { returns(T::Boolean) }
      def failed?
        errors?
      end

      # Check if the service has any errors.
      #
      # @return [Boolean] true if errors collection is not empty
      sig { returns(T::Boolean) }
      def errors?
        @errors.any?
      end

      # Check if the service has any warnings.
      #
      # @return [Boolean] true if warnings collection is not empty
      sig { returns(T::Boolean) }
      def warnings?
        @warnings.any?
      end

      # Stop executing remaining steps after the current step completes.
      #
      # @return [Boolean] true
      sig { returns(T::Boolean) }
      def stop!
        @stopped = true
      end
      alias done! stop!

      # Check if the service has been stopped.
      #
      # @return [Boolean] true if stop! was called
      sig { returns(T::Boolean) }
      def stopped?
        @stopped
      end
      alias done? stopped?

      # Stop execution immediately, skipping any remaining code in the current step.
      #
      # @raise [StopExecution] always raises to halt execution
      # @return [void]
      sig { returns(T.noreturn) }
      def stop_immediately!
        @stopped = true
        raise Light::Services::StopExecution
      end

      # Add an error to the :base key.
      #
      # @param message [String] the error message
      # @return [void]
      sig { params(message: String).void }
      def fail!(message)
        errors.add(:base, message)
      end

      # Add an error and stop execution immediately, causing transaction rollback.
      # Steps marked with `always: true` will still run after this method is called.
      #
      # @param message [String] the error message
      # @raise [FailExecution] always raises to halt execution and rollback
      # @return [void]
      sig { params(message: String).returns(T.noreturn) }
      def fail_immediately!(message)
        errors.add(:base, message, rollback: false)
        raise Light::Services::FailExecution
      end

      # Execute the service steps.
      #
      # @return [void]
      # @raise [StandardError] re-raises any exception after running always steps
      sig { void }
      def call
        load_defaults_and_validate

        run_callbacks(:before_service_run, self)

        run_callbacks(:around_service_run, self) do
          execute_service
        end

        run_service_result_callbacks
      rescue StandardError => e
        run_steps_with_always
        raise e
      end

      class << self
        extend T::Sig

        # @return [Hash, nil] class-level configuration options
        sig { returns(T.nilable(T::Hash[Symbol, T.untyped])) }
        attr_accessor :class_config

        # Set class-level configuration for this service.
        #
        # @param config [Hash] configuration options
        # @return [Hash] the configuration hash
        sig { params(config: T::Hash[Symbol, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
        def config(config = {})
          self.class_config = config
        end

        # Run the service and return the result.
        #
        # @param args [Hash] arguments to pass to the service
        # @param config [Hash] runtime configuration overrides
        # @return [Base] the executed service instance
        #
        # @example
        #   result = MyService.run(name: "test")
        #   result.success? # => true
        sig { params(args: T.untyped, config: T::Hash[Symbol, T.untyped]).returns(T.attached_class) }
        def run(args = {}, config = {})
          unless args.is_a?(Hash)
            raise Light::Services::ArgTypeError,
                  "#{self} expected arguments to be a Hash, " \
                  "but got #{args.class} (#{args.inspect})"
          end
          new(args, config).tap(&:call)
        end

        # Run the service and raise an error if it fails.
        #
        # @param args [Hash] arguments to pass to the service
        # @param config [Hash] runtime configuration overrides
        # @return [Base] the executed service instance
        # @raise [Error] if the service fails
        #
        # @example
        #   MyService.run!(name: "test") # raises if service fails
        sig { params(args: T::Hash[Symbol, T.untyped], config: T::Hash[Symbol, T.untyped]).returns(T.attached_class) }
        def run!(args = {}, config = {})
          run(args, config.merge(raise_on_error: true))
        end

        # Create a context for running the service with a parent service or config.
        #
        # @param service_or_config [Base, Hash] parent service or configuration hash
        # @param config [Hash] configuration hash (when first param is a service)
        # @return [BaseWithContext] context wrapper for running the service
        #
        # @example With parent service
        #   ChildService.with(self).run(data: value)
        #
        # @example With configuration
        #   MyService.with(use_transactions: false).run(name: "test")
        sig { params(service_or_config: T.untyped, config: T::Hash[Symbol, T.untyped]).returns(BaseWithContext) }
        def with(service_or_config = {}, config = {})
          # Validate service_or_config is the expected type
          unless service_or_config.is_a?(Hash) || service_or_config.is_a?(Base)
            raise Light::Services::ArgTypeError,
                  "#{self} expected a Hash or Light::Services::Base, " \
                  "but got #{service_or_config.class} (#{service_or_config.inspect})"
          end

          service = service_or_config.is_a?(Hash) ? nil : service_or_config
          resolved_config = service_or_config.is_a?(Hash) ? service_or_config : config

          BaseWithContext.new(self, service, resolved_config.dup)
        end
      end

      private

      # ============================================
      # Execution (inlined from concerns)
      # ============================================

      # Execute the main service logic
      sig { void }
      def execute_service
        # self.class has the steps DSL methods mixed in
        T.unsafe(self).class.validate_steps!
        run_steps
        run_steps_with_always
        @outputs.validate! if success?

        copy_warnings_to_parent_service
        copy_errors_to_parent_service
      end

      # Run all service result callbacks based on success/failure
      sig { void }
      def run_service_result_callbacks
        run_callbacks(:after_service_run, self)

        if success?
          run_callbacks(:on_service_success, self)
        else
          run_callbacks(:on_service_failure, self)
        end
      end

      # Run normal steps within transaction
      sig { void }
      def run_steps
        within_transaction do
          # Cache steps once for both normal and always execution
          # self.class has the steps DSL methods mixed in
          @cached_steps = T.unsafe(self).class.steps

          @cached_steps.each do |name, step|
            @launched_steps << name if step.run(self)

            break if @errors.break? || @warnings.break?
          end
        rescue Light::Services::StopExecution
          # Gracefully handle stop_immediately! inside transaction to prevent rollback
          @stopped = true
        end
      rescue Light::Services::FailExecution
        # FailExecution bubbles out of transaction (causing rollback) but is caught here
        nil
      end

      # Run steps with parameter `always` if they weren't launched because of errors/warnings
      sig { void }
      def run_steps_with_always
        # Use cached steps from run_steps, or get them if run_steps wasn't called
        # self.class has the steps DSL methods mixed in
        steps_to_check = @cached_steps || T.unsafe(self).class.steps

        steps_to_check.each do |name, step|
          next if !step.always || @launched_steps.include?(name)

          @launched_steps << name if step.run(self)
        end
      end

      # Load defaults for outputs and arguments, then validate arguments
      sig { void }
      def load_defaults_and_validate
        @outputs.load_defaults
        @arguments.load_defaults
        @arguments.validate!
      end

      # Execute block within transaction if configured
      sig { params(block: T.proc.void).returns(T.untyped) }
      def within_transaction(&block)
        if @config[:use_transactions] && defined?(ActiveRecord::Base)
          ActiveRecord::Base.transaction(requires_new: true, &block)
        else
          yield
        end
      end

      # ============================================
      # Parent Service (inlined from concerns)
      # ============================================

      # Copy warnings from this service to parent service
      sig { void }
      def copy_warnings_to_parent_service
        return if !@parent_service || !@config[:load_warnings]

        @parent_service.warnings.copy_from(
          @warnings,
          break: @config[:self_break_on_warning],
          rollback: @config[:self_rollback_on_warning],
        )
      end

      # Copy errors from this service to parent service
      sig { void }
      def copy_errors_to_parent_service
        return if !@parent_service || !@config[:load_errors]

        @parent_service.errors.copy_from(
          @errors,
          break: @config[:self_break_on_error],
          rollback: @config[:self_rollback_on_error],
        )
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end

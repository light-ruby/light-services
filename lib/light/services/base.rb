# frozen_string_literal: true

require "light/services/message"
require "light/services/messages"
require "light/services/base_with_context"

require "light/services/settings/step"
require "light/services/settings/field"

require "light/services/collection"

require "light/services/dsl/arguments_dsl"
require "light/services/dsl/outputs_dsl"
require "light/services/dsl/steps_dsl"

# Base class for all service objects
module Light
  module Services
    class Base
      include Callbacks
      include Dsl::ArgumentsDsl
      include Dsl::OutputsDsl
      include Dsl::StepsDsl

      # Getters
      attr_reader :outputs, :arguments, :errors, :warnings

      def initialize(args = {}, config = {}, parent_service = nil)
        @config = Light::Services.config.merge(self.class.class_config || {}).merge(config)
        @parent_service = parent_service

        @outputs = Collection::Base.new(self, :outputs)
        @arguments = Collection::Base.new(self, :arguments, args.dup)

        @done = false
        @launched_steps = []

        initialize_errors
        initialize_warnings
      end

      def success?
        !errors?
      end

      def failed?
        errors?
      end

      def errors?
        @errors.any?
      end

      def warnings?
        @warnings.any?
      end

      def done!
        @done = true
      end

      def done?
        @done
      end

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
        attr_accessor :class_config

        def config(config = {})
          self.class_config = config
        end

        def run(args = {}, config = {})
          new(args, config).tap(&:call)
        end

        def run!(args = {}, config = {})
          run(args, config.merge(raise_on_error: true))
        end

        def with(service_or_config = {}, config = {})
          service = service_or_config.is_a?(Hash) ? nil : service_or_config
          config = service_or_config unless service

          BaseWithContext.new(self, service, config.dup)
        end
      end

      private

      def execute_service
        run_steps
        run_steps_with_always
        @outputs.validate! if success?

        copy_warnings_to_parent_service
        copy_errors_to_parent_service
      end

      def run_service_result_callbacks
        run_callbacks(:after_service_run, self)

        if success?
          run_callbacks(:on_service_success, self)
        else
          run_callbacks(:on_service_failure, self)
        end
      end

      def initialize_errors
        @errors = Messages.new(
          break_on_add: @config[:break_on_error],
          raise_on_add: @config[:raise_on_error],
          rollback_on_add: @config[:use_transactions] && @config[:rollback_on_error],
        )
      end

      def initialize_warnings
        @warnings = Messages.new(
          break_on_add: @config[:break_on_warning],
          raise_on_add: @config[:raise_on_warning],
          rollback_on_add: @config[:use_transactions] && @config[:rollback_on_warning],
        )
      end

      def run_steps
        within_transaction do
          # Cache steps once for both normal and always execution
          @cached_steps = self.class.steps

          @cached_steps.each do |name, step|
            @launched_steps << name if step.run(self)

            break if @errors.break? || @warnings.break?
          end
        end
      end

      # Run steps with parameter `always` if they weren't launched because of errors/warnings
      def run_steps_with_always
        # Use cached steps from run_steps, or get them if run_steps wasn't called
        steps_to_check = @cached_steps || self.class.steps

        steps_to_check.each do |name, step|
          next if !step.always || @launched_steps.include?(name)

          @launched_steps << name if step.run(self)
        end
      end

      def copy_warnings_to_parent_service
        return if !@parent_service || !@config[:load_warnings]

        @parent_service.warnings.copy_from(
          @warnings,
          break: @config[:self_break_on_warning],
          rollback: @config[:self_rollback_on_warning],
        )
      end

      def copy_errors_to_parent_service
        return if !@parent_service || !@config[:load_errors]

        @parent_service.errors.copy_from(
          @errors,
          break: @config[:self_break_on_error],
          rollback: @config[:self_rollback_on_error],
        )
      end

      def load_defaults_and_validate
        @outputs.load_defaults
        @arguments.load_defaults
        @arguments.validate!
      end

      def within_transaction(&block)
        if @config[:use_transactions] && defined?(ActiveRecord::Base)
          ActiveRecord::Base.transaction(requires_new: true, &block)
        else
          yield
        end
      end
    end
  end
end

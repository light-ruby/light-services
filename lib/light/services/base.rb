# frozen_string_literal: true

require "light/services/message"
require "light/services/messages"
require "light/services/base_with_context"

require "light/services/settings/step"
require "light/services/settings/output"
require "light/services/settings/argument"

require "light/services/collection/base"
require "light/services/collection/outputs"
require "light/services/collection/arguments"

require "light/services/class_based_collection/base"
require "light/services/class_based_collection/mount"

# Base class for all service objects
module Light
  module Services
    class Base
      # Includes
      extend ClassBasedCollection::Mount

      # Settings
      mount_class_based_collection :steps,     item_class: Settings::Step,     shortcut: :step
      mount_class_based_collection :outputs,   item_class: Settings::Output,   shortcut: :output
      mount_class_based_collection :arguments, item_class: Settings::Argument, shortcut: :arg, allow_redefine: true

      # Arguments
      arg :verbose, default: false
      arg :benchmark, default: false
      arg :deepness, default: 0, context: true

      # Getters
      attr_reader :outputs, :arguments, :errors, :warnings

      def initialize(args = {}, config = {}, parent_service = nil)
        @config = Light::Services.config.merge(config)
        @parent_service = parent_service

        @outputs = Collection::Outputs.new(self)
        @arguments = Collection::Arguments.new(self, args)

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
        log_header if benchmark? || verbose?

        time = Benchmark.ms do
          run_steps
          run_steps_with_always

          copy_warnings_to_parent_service
          copy_errors_to_parent_service
        end

        return unless benchmark

        log "🟢 Finished #{self.class} in #{time}ms"
        puts
      rescue StandardError => e
        run_steps_with_always
        raise e
      end

      class << self
        def run(args = {}, config = {})
          new(args, config).tap(&:call)
        end

        def run!(args = {})
          run(args, raise_on_error: true)
        end

        def with(service_or_config = {}, config = {})
          service = service_or_config.is_a?(Hash) ? nil : service_or_config
          config = service_or_config unless service

          BaseWithContext.new(self, service, config)
        end
      end

      # TODO: Add possibility to specify logger
      def log(message)
        puts "#{'  ' * deepness}→ #{message}"
      end

      private

      def initialize_errors
        @errors = Messages.new(
          break_on_add: @config[:break_on_error],
          raise_on_add: @config[:raise_on_error],
          rollback_on_add: @config[:use_transactions] && @config[:rollback_on_error]
        )
      end

      def initialize_warnings
        @warnings = Messages.new(
          break_on_add: @config[:break_on_warning],
          raise_on_add: @config[:raise_on_warning],
          rollback_on_add: @config[:use_transactions] && @config[:rollback_on_warning]
        )
      end

      def run_steps
        within_transaction do
          self.class.steps.each do |name, step|
            @launched_steps << name if step.run(self, benchmark: benchmark)

            break if @errors.break? || @warnings.break?
          end
        end
      end

      # Run steps with parameter `always` if they weren't launched because of errors/warnings
      def run_steps_with_always
        self.class.steps.each do |name, step|
          next if !step.always || @launched_steps.include?(name)

          @launched_steps << name if step.run(self)
        end
      end

      def copy_warnings_to_parent_service
        return if !@parent_service || !@config[:load_warnings]

        @parent_service.warnings.copy_from(
          @warnings,
          break: @config[:self_break_on_warning],
          rollback: @config[:self_rollback_on_warning]
        )
      end

      def copy_errors_to_parent_service
        return if !@parent_service || !@config[:load_errors]

        @parent_service.errors.copy_from(
          @errors,
          break: @config[:self_break_on_error],
          rollback: @config[:self_rollback_on_error]
        )
      end

      def load_defaults_and_validate
        @outputs.load_defaults
        @arguments.load_defaults
        @arguments.validate!
      end

      def log_header
        log "🏎 Run service #{self.class}"
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

# frozen_string_literal: true

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

      # Steps
      step :load_defaults_and_validate

      # Getters
      attr_reader :outputs, :arguments, :errors, :warnings

      def initialize(args = {}, config = {}, parent_service = nil)
        @config = Light::Services.config.merge(config)
        @parent_service = parent_service

        @outputs = Collection::Outputs.new(self)
        @arguments = Collection::Arguments.new(self, args)

        @launched_steps = []

        initialize_errors
        initialize_warnings
      end

      def run
        run_steps
        run_always_steps
        load_data_into_parent_service if @parent_service
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

      class << self
        def run(args = {})
          new(args).tap(&:run)
        end

        def with(service_or_config = {}, config = {})
          service = service_or_config.is_a?(Hash) ? nil : service_or_config
          config = service ? config : service_or_config

          BaseWithContext.new(self, service, config)
        end
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
            @launched_steps << name if step.run(self)

            break if @errors.break? || @warnings.break?
          end
        end
      end

      # Run steps with parameter `always` if they weren't launched because of errors/warnings
      def run_always_steps
        self.class.steps.each do |name, step|
          next if !step.always || @launched_steps.include?(name)

          @launched_steps << name if step.run(self)
        end
      end

      def load_data_into_parent_service
        # TODO: Add `self_rollback_on_error` (and others) for parent class
        @parent_service.errors.from(@errors) if @config[:load_errors]
        @parent_service.warnings.from(@warnings) if @config[:load_warnings]
      end

      def load_defaults_and_validate
        @outputs.load_defaults
        @arguments.load_defaults
        @arguments.validate!
      end

      def within_transaction
        if @config[:use_transactions] && defined?(ActiveRecord::Base)
          ActiveRecord::Base.transaction(requires_new: true) do
            yield
          end
        else
          yield
        end
      end
    end
  end
end

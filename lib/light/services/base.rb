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


module Light
  module Services
    class Base
      # Includes
      extend ClassBasedCollection::Mount

      # Settings
      mount_class_based_collection :steps,     klass: Settings::Step,     shortcut: :step
      mount_class_based_collection :outputs,   klass: Settings::Output,   shortcut: :output
      mount_class_based_collection :arguments, klass: Settings::Argument, shortcut: :arg

      # Steps
      step :load_defaults_and_validate

      # Getters
      attr_reader :outputs, :arguments, :errors, :warnings

      def initialize(args = {}, config = {}, parent_service = nil)
        @config = Light::Services.config.to_h.merge(config)
        @parent_service = parent_service

        @outputs = Collection::Outputs.new(self)
        @arguments = Collection::Arguments.new(self, args)

        @errors = Messages.new(
          break_on_add: @config[:break_on_error],
          raise_on_add: @config[:raise_on_error],
          rollback_on_add: @config[:use_transactions] && @config[:rollback_on_error]
        )

        @warnings = Messages.new(
          break_on_add: @config[:break_on_warning],
          raise_on_add: @config[:raise_on_warning],
          rollback_on_add: @config[:use_transactions] && @config[:rollback_on_warning]
        )
      end

      def run
        self.class.steps.each do |step|
          step.run(self)

          break if @errors.break? || @warnings.break?
        end

        return unless @parent_service

        # TODO: Add `self_rollback_on_error` (and others) for parent class
        @parent_service.errors.from(@errors) if @config[:load_errors]
        @parent_service.warnings.from(@warnings) if @config[:load_warnings]
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

      def load_defaults_and_validate
        @outputs.load_defaults
        @arguments.load_defaults
        @arguments.validate!
      end
    end
  end
end

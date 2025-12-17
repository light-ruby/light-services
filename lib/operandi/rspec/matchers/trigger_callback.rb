# frozen_string_literal: true

module Operandi
  module RSpec
    module Matchers
      # Matcher for testing callback execution on a service instance
      # NOTE: This matcher requires the service to track callback execution.
      # Add tracking in your callbacks:
      #
      #   before_service_run do |service|
      #     service.callback_log << :before_service_run
      #   end
      #
      #   after_step_run do |service, step_name|
      #     service.callback_log << [:after_step_run, step_name]
      #   end
      #
      # @example Basic callback check (requires callback_log tracking)
      #   expect(service).to trigger_callback(:before_service_run)
      #
      # @example Step-specific callback
      #   expect(service).to trigger_callback(:after_step_run).for_step(:validate)
      #
      # @example Check callback was not triggered
      #   expect(service).not_to trigger_callback(:on_service_failure)
      def trigger_callback(callback_name)
        TriggerCallbackMatcher.new(callback_name)
      end

      class TriggerCallbackMatcher
        VALID_CALLBACKS = [
          :before_service_run,
          :after_service_run,
          :around_service_run,
          :on_service_success,
          :on_service_failure,
          :before_step_run,
          :after_step_run,
          :around_step_run,
          :on_step_success,
          :on_step_failure,
          :on_step_crash,
        ].freeze

        STEP_CALLBACKS = [
          :before_step_run,
          :after_step_run,
          :around_step_run,
          :on_step_success,
          :on_step_failure,
          :on_step_crash,
        ].freeze

        def initialize(callback_name)
          @callback_name = callback_name
          @step_name = nil
        end

        def for_step(step_name)
          @step_name = step_name
          self
        end

        def matches?(service)
          @service = service

          return false unless service_tracks_callbacks?
          return false unless callback_triggered?

          true
        end

        def failure_message
          return tracking_not_available_message unless service_tracks_callbacks?

          if @step_name
            "expected service to trigger callback :#{@callback_name} for step :#{@step_name}, " \
              "but callback log was: #{callback_log.inspect}"
          else
            "expected service to trigger callback :#{@callback_name}, " \
              "but callback log was: #{callback_log.inspect}"
          end
        end

        def failure_message_when_negated
          if @step_name
            "expected service not to trigger callback :#{@callback_name} for step :#{@step_name}"
          else
            "expected service not to trigger callback :#{@callback_name}"
          end
        end

        def description
          desc = "trigger callback :#{@callback_name}"
          desc += " for step :#{@step_name}" if @step_name
          desc
        end

        private

        def service_tracks_callbacks?
          @service.respond_to?(:callback_log)
        end

        def callback_log
          @service.callback_log
        end

        def callback_triggered?
          if @step_name
            # Look for step-specific callback entry like [:after_step_run, :validate]
            callback_log.include?([@callback_name, @step_name])
          else
            # Look for service-level callback or any occurrence of the callback name
            callback_log.any? do |entry|
              case entry
              when Symbol
                entry == @callback_name
              when Array
                entry.first == @callback_name
              else
                false
              end
            end
          end
        end

        def tracking_not_available_message
          "cannot verify callback execution because service does not track callbacks. " \
            "Add callback tracking to your service, e.g.: " \
            "`before_service_run { |service| service.callback_log << :before_service_run }`"
        end
      end
    end
  end
end

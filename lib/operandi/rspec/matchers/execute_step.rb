# frozen_string_literal: true

module Operandi
  module RSpec
    module Matchers
      # Matcher for testing step execution on a service instance
      # NOTE: This matcher requires the service to track executed steps.
      # Add a callback in your service to track execution:
      #
      #   after_step_run do |service, step_name|
      #     service.executed_steps << step_name
      #   end
      #
      # @example Basic usage (requires executed_steps tracking)
      #   expect(service).to execute_step(:validate)
      #
      # @example Check step was skipped
      #   expect(service).to skip_step(:notify)
      #
      # @example Check multiple steps executed
      #   expect(service).to execute_steps(:validate, :process, :save)
      #
      # @example Check execution order
      #   expect(service).to execute_steps_in_order(:validate, :process, :save)
      def execute_step(name)
        ExecuteStepMatcher.new(name)
      end

      def skip_step(name)
        SkipStepMatcher.new(name)
      end

      def execute_steps(*names)
        ExecuteStepsMatcher.new(names, ordered: false)
      end

      def execute_steps_in_order(*names)
        ExecuteStepsMatcher.new(names, ordered: true)
      end

      class ExecuteStepMatcher
        def initialize(name)
          @name = name
        end

        def matches?(service)
          @service = service

          return false unless service_tracks_steps?
          return false unless step_executed?

          true
        end

        def failure_message
          return tracking_not_available_message unless service_tracks_steps?

          "expected service to execute step :#{@name}, " \
            "but executed steps were: #{executed_steps.inspect}"
        end

        def failure_message_when_negated
          "expected service not to execute step :#{@name}"
        end

        def description
          "execute step :#{@name}"
        end

        private

        def service_tracks_steps?
          @service.respond_to?(:executed_steps)
        end

        def executed_steps
          @service.executed_steps
        end

        def step_executed?
          executed_steps.include?(@name)
        end

        def tracking_not_available_message
          "cannot verify step execution because service does not track executed steps. " \
            "Add `after_step_run { |service, step| service.executed_steps << step }` to your service."
        end
      end

      class SkipStepMatcher
        def initialize(name)
          @name = name
        end

        def matches?(service)
          @service = service

          return false unless service_tracks_steps?
          return false unless step_skipped?

          true
        end

        def failure_message
          return tracking_not_available_message unless service_tracks_steps?

          "expected service to skip step :#{@name}, but it was executed. " \
            "Executed steps: #{executed_steps.inspect}"
        end

        def failure_message_when_negated
          "expected service not to skip step :#{@name} (expected it to execute)"
        end

        def description
          "skip step :#{@name}"
        end

        private

        def service_tracks_steps?
          @service.respond_to?(:executed_steps)
        end

        def executed_steps
          @service.executed_steps
        end

        def step_skipped?
          !executed_steps.include?(@name)
        end

        def tracking_not_available_message
          "cannot verify step execution because service does not track executed steps. " \
            "Add `after_step_run { |service, step| service.executed_steps << step }` to your service."
        end
      end

      class ExecuteStepsMatcher
        def initialize(names, ordered:)
          @names = names
          @ordered = ordered
        end

        def matches?(service)
          @service = service
          @missing_steps = []

          return false unless service_tracks_steps?
          return false unless all_steps_executed?
          return false unless order_matches?

          true
        end

        def failure_message
          return tracking_not_available_message unless service_tracks_steps?
          return missing_steps_failure_message unless all_steps_executed?
          return order_failure_message unless order_matches?

          ""
        end

        def failure_message_when_negated
          if @ordered
            "expected service not to execute steps #{@names.inspect} in that order"
          else
            "expected service not to execute steps #{@names.inspect}"
          end
        end

        def description
          if @ordered
            "execute steps #{@names.inspect} in order"
          else
            "execute steps #{@names.inspect}"
          end
        end

        private

        def service_tracks_steps?
          @service.respond_to?(:executed_steps)
        end

        def executed_steps
          @service.executed_steps
        end

        def all_steps_executed?
          @missing_steps = @names.reject { |name| executed_steps.include?(name) }
          @missing_steps.empty?
        end

        def order_matches?
          return true unless @ordered

          # Check if the expected steps appear in the same order in executed steps
          last_index = -1
          @names.all? do |name|
            current_index = executed_steps.index(name)
            return false unless current_index
            return false unless current_index > last_index

            last_index = current_index
            true
          end
        end

        def missing_steps_failure_message
          "expected service to execute steps #{@names.inspect}, " \
            "but missing: #{@missing_steps.inspect}. " \
            "Executed steps: #{executed_steps.inspect}"
        end

        def order_failure_message
          "expected service to execute steps #{@names.inspect} in that order, " \
            "but actual execution order was: #{executed_steps.inspect}"
        end

        def tracking_not_available_message
          "cannot verify step execution because service does not track executed steps. " \
            "Add `after_step_run { |service, step| service.executed_steps << step }` to your service."
        end
      end
    end
  end
end

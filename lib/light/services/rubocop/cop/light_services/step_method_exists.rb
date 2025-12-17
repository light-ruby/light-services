# frozen_string_literal: true
# typed: false

module RuboCop
  module Cop
    module LightServices
      # Ensures that all `step` declarations have a corresponding method defined in the same class.
      #
      # Note: This cop only checks for methods defined in the same file/class. It cannot detect
      # methods inherited from parent classes. Use the `ExcludedSteps` option or `rubocop:disable`
      # comments for inherited steps.
      #
      # @example
      #   # bad
      #   class MyService < ApplicationService
      #     step :validate
      #     step :process
      #
      #     private
      #
      #     def validate
      #       # only validate is defined, process is missing
      #     end
      #   end
      #
      #   # good
      #   class MyService < ApplicationService
      #     step :validate
      #     step :process
      #
      #     private
      #
      #     def validate
      #       # validation logic
      #     end
      #
      #     def process
      #       # processing logic
      #     end
      #   end
      #
      # @example ExcludedSteps: ['initialize_entity', 'assign_attributes'] (default: [])
      #   # good - these steps are excluded from checking
      #   class User::Create < CreateService
      #     step :initialize_entity
      #     step :assign_attributes
      #     step :send_welcome_email
      #
      #     private
      #
      #     def send_welcome_email
      #       # only this method needs to be defined
      #     end
      #   end
      #
      class StepMethodExists < Base
        MSG = "Step `%<name>s` has no corresponding method. " \
              "For inherited steps, disable this line or add to ExcludedSteps."

        def on_class(_node)
          @step_calls = []
          @defined_methods = []
        end

        def on_send(node)
          return unless step_call?(node)

          step_name = node.arguments.first&.value
          return unless step_name

          @step_calls ||= []
          @step_calls << { name: step_name, node: node }
        end

        def on_def(node)
          @defined_methods ||= []
          @defined_methods << node.method_name
        end

        def after_class(_node)
          return unless @step_calls&.any?

          @step_calls.each do |step|
            next if @defined_methods&.include?(step[:name])
            next if excluded_step?(step[:name])

            add_offense(step[:node], message: format(MSG, name: step[:name]))
          end
        end

        private

        def step_call?(node)
          node.send_type? &&
            node.method_name == :step &&
            node.receiver.nil? &&
            node.arguments.first&.sym_type?
        end

        def excluded_step?(step_name)
          excluded_steps.include?(step_name.to_s)
        end

        def excluded_steps
          cop_config.fetch("ExcludedSteps", [])
        end
      end
    end
  end
end

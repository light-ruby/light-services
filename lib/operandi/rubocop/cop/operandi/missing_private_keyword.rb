# frozen_string_literal: true

module RuboCop
  module Cop
    module Operandi
      # Ensures that step methods are defined as private.
      # Step methods are implementation details and should not be part of the public API.
      #
      # @example
      #   # bad
      #   class MyService < ApplicationService
      #     step :process
      #     step :notify
      #
      #     def process
      #       # This should be private
      #     end
      #
      #     def notify
      #       # This should be private
      #     end
      #   end
      #
      #   # good
      #   class MyService < ApplicationService
      #     step :process
      #     step :notify
      #
      #     private
      #
      #     def process
      #       # Now private
      #     end
      #
      #     def notify
      #       # Now private
      #     end
      #   end
      #
      class MissingPrivateKeyword < Base
        MSG = "Step method `%<name>s` should be private."

        def on_class(_node)
          @step_names = []
          @private_section_started = false
          @public_step_methods = []
        end

        def on_send(node)
          if step_call?(node)
            step_name = node.arguments.first&.value
            @step_names ||= []
            @step_names << step_name if step_name
          elsif private_declaration?(node)
            @private_section_started = true
          elsif public_declaration?(node)
            @private_section_started = false
          end
        end

        def on_def(node)
          return unless @step_names&.include?(node.method_name)
          return if @private_section_started

          @public_step_methods ||= []
          @public_step_methods << node
        end

        def after_class(_node)
          return unless @public_step_methods&.any?

          @public_step_methods.each do |node|
            add_offense(node, message: format(MSG, name: node.method_name))
          end
        end

        private

        def step_call?(node)
          node.send_type? &&
            node.method_name == :step &&
            node.receiver.nil? &&
            node.arguments.first&.sym_type?
        end

        def private_declaration?(node)
          node.send_type? &&
            node.method_name == :private &&
            node.receiver.nil? &&
            node.arguments.empty?
        end

        def public_declaration?(node)
          node.send_type? &&
            node.method_name == :public &&
            node.receiver.nil? &&
            node.arguments.empty?
        end
      end
    end
  end
end

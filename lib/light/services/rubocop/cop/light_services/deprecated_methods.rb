# frozen_string_literal: true
# typed: false

module RuboCop
  module Cop
    module LightServices
      # Detects deprecated `done!` and `done?` method calls and suggests
      # using `stop!` and `stopped?` instead.
      #
      # This cop checks calls inside service classes that inherit from
      # Light::Services::Base or any configured base service classes.
      #
      # @safety
      #   This cop's autocorrection is safe as `done!` and `done?` are
      #   direct aliases for `stop!` and `stopped?`.
      #
      # @example
      #   # bad
      #   class User::Create < ApplicationService
      #     step :process
      #
      #     private
      #
      #     def process
      #       done! if condition_met?
      #       return if done?
      #     end
      #   end
      #
      #   # good
      #   class User::Create < ApplicationService
      #     step :process
      #
      #     private
      #
      #     def process
      #       stop! if condition_met?
      #       return if stopped?
      #     end
      #   end
      #
      class DeprecatedMethods < Base
        extend AutoCorrector

        MSG_DONE_BANG = "Use `stop!` instead of deprecated `done!`."
        MSG_DONE_QUERY = "Use `stopped?` instead of deprecated `done?`."

        RESTRICT_ON_SEND = [:done!, :done?].freeze

        REPLACEMENTS = {
          done!: :stop!,
          done?: :stopped?,
        }.freeze

        DEFAULT_BASE_CLASSES = ["ApplicationService"].freeze

        def on_class(node)
          @in_service_class = service_class?(node)
        end

        def after_class(_node)
          @in_service_class = false
        end

        def on_send(node)
          return unless @in_service_class
          return unless RESTRICT_ON_SEND.include?(node.method_name)
          return if node.receiver && !self_receiver?(node)

          message = node.method_name == :done! ? MSG_DONE_BANG : MSG_DONE_QUERY
          replacement = REPLACEMENTS[node.method_name]

          add_offense(node, message: message) do |corrector|
            if node.receiver
              corrector.replace(node, "self.#{replacement}")
            else
              corrector.replace(node, replacement.to_s)
            end
          end
        end

        private

        def service_class?(node)
          return false unless node.parent_class

          parent_class_name = extract_class_name(node.parent_class)
          return false unless parent_class_name

          # Check for direct Light::Services::Base inheritance
          return true if parent_class_name == "Light::Services::Base"

          # Check against configured base service classes
          base_classes = cop_config.fetch("BaseServiceClasses", DEFAULT_BASE_CLASSES)
          base_classes.include?(parent_class_name)
        end

        def extract_class_name(node)
          case node.type
          when :const
            node.const_name
          when :send
            # For namespaced constants like Light::Services::Base
            node.source
          end
        end

        def self_receiver?(node)
          node.receiver&.self_type?
        end
      end
    end
  end
end

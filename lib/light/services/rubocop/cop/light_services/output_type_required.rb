# frozen_string_literal: true

module RuboCop
  module Cop
    module LightServices
      # Ensures that all `output` declarations in Light::Services include a `type:` option.
      #
      # @example
      #   # bad
      #   output :result
      #   output :data, optional: true
      #   output :count, default: 0
      #
      #   # good
      #   output :result, type: Hash
      #   output :data, type: Hash, optional: true
      #   output :count, type: Integer, default: 0
      #
      class OutputTypeRequired < Base
        MSG = "Output `%<name>s` must have a `type:` option."

        RESTRICT_ON_SEND = [:output].freeze

        # @!method output_call?(node)
        def_node_matcher :output_call?, <<~PATTERN
          (send nil? :output (sym $_) ...)
        PATTERN

        def on_send(node)
          output_call?(node) do |name|
            return if has_type_option?(node)

            add_offense(node, message: format(MSG, name: name))
          end
        end

        private

        def has_type_option?(node)
          # output :name (no options)
          return false if node.arguments.size == 1

          # output :name, type: Foo or output :name, { type: Foo }
          opts_node = node.arguments[1]
          return false unless opts_node&.hash_type?

          opts_node.pairs.any? { |pair| pair.key.sym_type? && pair.key.value == :type }
        end
      end
    end
  end
end

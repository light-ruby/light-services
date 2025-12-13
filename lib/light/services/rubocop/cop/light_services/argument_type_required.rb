# frozen_string_literal: true

module RuboCop
  module Cop
    module LightServices
      # Ensures that all `arg` declarations in Light::Services include a `type:` option.
      #
      # @example
      #   # bad
      #   arg :user_id
      #   arg :params, default: {}
      #   arg :name, optional: true
      #
      #   # good
      #   arg :user_id, type: Integer
      #   arg :params, type: Hash, default: {}
      #   arg :name, type: String, optional: true
      #
      class ArgumentTypeRequired < Base
        MSG = "Argument `%<name>s` must have a `type:` option."

        RESTRICT_ON_SEND = [:arg].freeze

        # @!method arg_call?(node)
        def_node_matcher :arg_call?, <<~PATTERN
          (send nil? :arg (sym $_) ...)
        PATTERN

        def on_send(node)
          arg_call?(node) do |name|
            return if has_type_option?(node)

            add_offense(node, message: format(MSG, name: name))
          end
        end

        private

        def has_type_option?(node)
          # arg :name (no options)
          return false if node.arguments.size == 1

          # arg :name, type: Foo or arg :name, { type: Foo }
          opts_node = node.arguments[1]
          return false unless opts_node&.hash_type?

          opts_node.pairs.any? { |pair| pair.key.sym_type? && pair.key.value == :type }
        end
      end
    end
  end
end

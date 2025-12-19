# frozen_string_literal: true

module RuboCop
  module Cop
    module Operandi
      # Detects when `optional: true` is used together with `default:` option.
      # Having a default value implies the argument/output is optional, making
      # `optional: true` redundant.
      #
      # @safety
      #   This cop is safe to autocorrect.
      #
      # @example
      #   # bad
      #   arg :name, type: String, optional: true, default: "guest"
      #   output :count, type: Integer, optional: true, default: 0
      #
      #   # good
      #   arg :name, type: String, default: "guest"
      #   output :count, type: Integer, default: 0
      #
      class RedundantOptional < Base
        extend AutoCorrector

        MSG = "`optional: true` is redundant when `default:` is specified for `%<name>s`."

        RESTRICT_ON_SEND = [:arg, :output].freeze

        # @!method field_call?(node)
        def_node_matcher :field_call?, <<~PATTERN
          (send nil? {:arg :output} (sym $_) ...)
        PATTERN

        def on_send(node)
          field_call?(node) do |name|
            optional_pair = find_optional_true_pair(node)
            return unless optional_pair && has_default_option?(node)

            add_offense(node, message: format(MSG, name: name)) do |corrector|
              remove_hash_pair(corrector, node.arguments[1], optional_pair)
            end
          end
        end

        private

        def options_hash(node)
          return nil if node.arguments.size == 1

          opts = node.arguments[1]
          opts if opts&.hash_type?
        end

        def find_optional_true_pair(node)
          opts = options_hash(node)
          return nil unless opts

          opts.pairs.find { |pair| optional_true_pair?(pair) }
        end

        def optional_true_pair?(pair)
          pair.key.sym_type? && pair.key.value == :optional && pair.value.true_type?
        end

        def has_default_option?(node)
          opts = options_hash(node)
          return false unless opts

          opts.pairs.any? { |pair| pair.key.sym_type? && pair.key.value == :default }
        end

        def remove_hash_pair(corrector, hash_node, pair_to_remove)
          pairs = hash_node.pairs
          pair_index = pairs.index(pair_to_remove)

          if last_pair?(pairs, pair_index)
            remove_last_pair(corrector, pairs, pair_index, pair_to_remove)
          else
            remove_non_last_pair(corrector, pairs, pair_index, pair_to_remove)
          end
        end

        def last_pair?(pairs, pair_index)
          pair_index == pairs.size - 1
        end

        def remove_last_pair(corrector, pairs, pair_index, pair_to_remove)
          prev_pair = pairs[pair_index - 1]
          corrector.remove(range_between(prev_pair.source_range.end_pos, pair_to_remove.source_range.end_pos))
        end

        def remove_non_last_pair(corrector, pairs, pair_index, pair_to_remove)
          next_pair = pairs[pair_index + 1]
          corrector.remove(range_between(pair_to_remove.source_range.begin_pos, next_pair.source_range.begin_pos))
        end

        def range_between(start_pos, end_pos)
          Parser::Source::Range.new(processed_source.buffer, start_pos, end_pos)
        end
      end
    end
  end
end

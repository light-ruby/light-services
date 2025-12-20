# frozen_string_literal: true

module RuboCop
  module Cop
    module Operandi
      # Detects when `default: nil` is used instead of `optional: true`.
      # Using `optional: true` is the preferred way to indicate an optional field
      # with no default value.
      #
      # @safety
      #   This cop is safe to autocorrect.
      #
      # @example
      #   # bad
      #   arg :user, type: User, default: nil
      #   output :result, type: Hash, default: nil
      #
      #   # good
      #   arg :user, type: User, optional: true
      #   output :result, type: Hash, optional: true
      #
      #   # bad - redundant default: nil with optional: true
      #   arg :user, type: User, optional: true, default: nil
      #
      #   # good
      #   arg :user, type: User, optional: true
      #
      class PreferOptionalOverDefaultNil < Base
        extend AutoCorrector

        MSG = "Prefer `optional: true` over `default: nil` for `%<name>s`."
        MSG_REDUNDANT = "`default: nil` is redundant when `optional: true` is specified for `%<name>s`."

        RESTRICT_ON_SEND = [:arg, :output].freeze

        # @!method field_call?(node)
        def_node_matcher :field_call?, <<~PATTERN
          (send nil? {:arg :output} (sym $_) ...)
        PATTERN

        def on_send(node)
          field_call?(node) do |name|
            default_nil_pair = find_default_nil_pair(node)
            return unless default_nil_pair

            optional_pair = find_optional_true_pair(node)

            if optional_pair
              # Both optional: true and default: nil - remove default: nil
              add_offense(node, message: format(MSG_REDUNDANT, name: name)) do |corrector|
                remove_hash_pair(corrector, node.arguments[1], default_nil_pair)
              end
            else
              # Only default: nil - replace with optional: true
              add_offense(node, message: format(MSG, name: name)) do |corrector|
                corrector.replace(default_nil_pair.source_range, "optional: true")
              end
            end
          end
        end

        private

        def options_hash(node)
          return nil if node.arguments.size == 1

          opts = node.arguments[1]
          opts if opts&.hash_type?
        end

        def find_default_nil_pair(node)
          opts = options_hash(node)
          return nil unless opts

          opts.pairs.find { |pair| default_nil_pair?(pair) }
        end

        def default_nil_pair?(pair)
          pair.key.sym_type? && pair.key.value == :default && pair.value.nil_type?
        end

        def find_optional_true_pair(node)
          opts = options_hash(node)
          return nil unless opts

          opts.pairs.find { |pair| optional_true_pair?(pair) }
        end

        def optional_true_pair?(pair)
          pair.key.sym_type? && pair.key.value == :optional && pair.value.true_type?
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

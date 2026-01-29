# frozen_string_literal: true

module RubyLsp
  module Operandi
    class Definition
      # Condition options that reference methods
      CONDITION_OPTIONS = [:if, :unless].freeze

      def initialize(response_builder, uri, node_context, index, dispatcher)
        @response_builder = response_builder
        @uri = uri
        @node_context = node_context
        @index = index

        # Register for symbol nodes - this is what gets triggered when user clicks on :method_name
        dispatcher.register(self, :on_symbol_node_enter)
      end

      # Called when cursor is on a symbol node (e.g., :validate in `step :validate`)
      def on_symbol_node_enter(node)
        # Check if this symbol is part of a step call by examining the call context
        call_node = find_parent_step_call
        return unless call_node

        method_name = determine_method_name(node, call_node)
        return unless method_name

        find_and_append_method_location(method_name)
      end

      private

      # Find the parent step call node from the node context
      # The node_context.call_node returns the enclosing call if cursor is on an argument
      def find_parent_step_call
        call_node = @node_context.call_node
        return unless call_node
        return unless call_node.name == :step

        call_node
      end

      # Determine which method name to look up based on where the symbol appears
      # Returns nil if this symbol is not a method reference we should handle
      def determine_method_name(symbol_node, call_node)
        symbol_value = symbol_node.value.to_sym

        # Check if this is the first argument (step method name)
        first_arg = call_node.arguments&.arguments&.first
        if first_arg.is_a?(Prism::SymbolNode) && first_arg.value.to_sym == symbol_value && same_location?(
          first_arg,
          symbol_node,
        )
          # Verify the symbol node location matches (same node, not just same value)
          return symbol_value.to_s
        end

        # Check if this is a condition option (if: or unless:)
        keyword_hash = find_keyword_hash(call_node)
        return unless keyword_hash

        CONDITION_OPTIONS.each do |option_name|
          condition_symbol = find_symbol_option(keyword_hash, option_name)
          next unless condition_symbol
          next unless same_location?(condition_symbol, symbol_node)

          return condition_symbol.value.to_s
        end

        nil
      end

      # Check if two nodes have the same location (are the same node)
      def same_location?(node1, node2)
        node1.location.start_offset == node2.location.start_offset &&
          node1.location.end_offset == node2.location.end_offset
      end

      # Find the keyword hash in call arguments
      def find_keyword_hash(node)
        node.arguments&.arguments&.find { |arg| arg.is_a?(Prism::KeywordHashNode) }
      end

      # Find a symbol value for a specific option in the keyword hash
      # Returns the SymbolNode if found and value is a symbol, nil otherwise
      def find_symbol_option(keyword_hash, option_name)
        element = keyword_hash.elements.find do |elem|
          elem.is_a?(Prism::AssocNode) &&
            elem.key.is_a?(Prism::SymbolNode) &&
            elem.key.value.to_sym == option_name
        end

        return unless element
        return unless element.value.is_a?(Prism::SymbolNode)

        element.value
      end

      # Find method definition in index and append location to response
      def find_and_append_method_location(method_name)
        owner_name = @node_context.nesting.join("::")
        return if owner_name.empty?

        # Look up method entries in the index
        method_entries = @index.resolve_method(method_name, owner_name)
        return unless method_entries&.any?

        method_entries.each { |entry| append_location(entry) }

        true
      end

      def append_location(entry)
        @response_builder << Interface::Location.new(
          uri: URI::Generic.from_path(path: entry.file_path).to_s,
          range: build_range(entry.location),
        )
      end

      def build_range(location)
        Interface::Range.new(
          start: Interface::Position.new(
            line: location.start_line - 1,
            character: location.start_column,
          ),
          end: Interface::Position.new(
            line: location.end_line - 1,
            character: location.end_column,
          ),
        )
      end
    end
  end
end

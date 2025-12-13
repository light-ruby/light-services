# frozen_string_literal: true

module RubyLsp
  module LightServices
    class IndexingEnhancement < RubyIndexer::Enhancement # rubocop:disable Metrics/ClassLength
      # DSL methods that generate getter, predicate, and setter methods
      FIELD_DSL_METHODS = [:arg, :output].freeze

      # Default type mappings for common dry-types to their underlying Ruby types
      # These can be extended via Light::Services.config.ruby_lsp_type_mappings
      DEFAULT_TYPE_MAPPINGS = {
        "Types::String" => "String",
        "Types::Strict::String" => "String",
        "Types::Coercible::String" => "String",
        "Types::Integer" => "Integer",
        "Types::Strict::Integer" => "Integer",
        "Types::Coercible::Integer" => "Integer",
        "Types::Float" => "Float",
        "Types::Strict::Float" => "Float",
        "Types::Coercible::Float" => "Float",
        "Types::Decimal" => "BigDecimal",
        "Types::Strict::Decimal" => "BigDecimal",
        "Types::Coercible::Decimal" => "BigDecimal",
        "Types::Bool" => "TrueClass | FalseClass",
        "Types::Strict::Bool" => "TrueClass | FalseClass",
        "Types::True" => "TrueClass",
        "Types::Strict::True" => "TrueClass",
        "Types::False" => "FalseClass",
        "Types::Strict::False" => "FalseClass",
        "Types::Array" => "Array",
        "Types::Strict::Array" => "Array",
        "Types::Hash" => "Hash",
        "Types::Strict::Hash" => "Hash",
        "Types::Symbol" => "Symbol",
        "Types::Strict::Symbol" => "Symbol",
        "Types::Coercible::Symbol" => "Symbol",
        "Types::Date" => "Date",
        "Types::Strict::Date" => "Date",
        "Types::DateTime" => "DateTime",
        "Types::Strict::DateTime" => "DateTime",
        "Types::Time" => "Time",
        "Types::Strict::Time" => "Time",
        "Types::Nil" => "NilClass",
        "Types::Strict::Nil" => "NilClass",
        "Types::Any" => "Object",
      }.freeze

      # ─────────────────────────────────────────────────────────────────────────
      # Public API - Called by Ruby LSP indexer
      # ─────────────────────────────────────────────────────────────────────────

      # Called when the indexer encounters a method call node
      # Detects `arg` and `output` DSL calls and registers the generated methods
      def on_call_node_enter(node)
        return unless @listener.current_owner
        return unless FIELD_DSL_METHODS.include?(node.name)

        field_name = extract_field_name(node)
        return unless field_name

        ruby_type = extract_ruby_type(node)
        register_field_methods(field_name, node.location, ruby_type)
      end

      def on_call_node_leave(node); end

      private

      # ─────────────────────────────────────────────────────────────────────────
      # Field Extraction
      # ─────────────────────────────────────────────────────────────────────────

      # Extract the field name from the first argument (symbol)
      # Example: `arg :user` → "user"
      def extract_field_name(node)
        arguments = node.arguments&.arguments
        return unless arguments&.any?

        first_arg = arguments.first
        return unless first_arg.is_a?(Prism::SymbolNode)

        first_arg.value
      end

      # ─────────────────────────────────────────────────────────────────────────
      # Type Resolution
      # ─────────────────────────────────────────────────────────────────────────

      # Extract and resolve the Ruby type from the `type:` keyword argument
      # Returns the mapped Ruby type string or the original type if no mapping exists
      def extract_ruby_type(node)
        type_node = find_type_value_node(node)
        return unless type_node

        resolve_to_ruby_type(type_node)
      end

      # Find the value node for the `type:` keyword argument
      def find_type_value_node(node)
        arguments = node.arguments&.arguments
        return unless arguments

        keyword_hash = arguments.find { |arg| arg.is_a?(Prism::KeywordHashNode) }
        return unless keyword_hash

        # NOTE: Prism's SymbolNode#value returns a String, not a Symbol
        type_element = keyword_hash.elements.find do |element|
          element.is_a?(Prism::AssocNode) &&
            element.key.is_a?(Prism::SymbolNode) &&
            element.key.value == "type"
        end

        type_element&.value
      end

      # Resolve a Prism type node to a Ruby type string
      # Handles constants, constant paths, and method chains
      def resolve_to_ruby_type(node)
        type_string = node_to_constant_string(node)
        return unless type_string

        map_to_ruby_type(type_string) || type_string
      end

      # Convert a Prism node to its constant string representation
      def node_to_constant_string(node)
        case node
        when Prism::ConstantReadNode
          node.name.to_s
        when Prism::ConstantPathNode
          build_constant_path(node)
        when Prism::CallNode
          # Handle method chains like Types::String.constrained(...) or Types::Array.of(...)
          extract_receiver_constant(node)
        end
      end

      # Build a full constant path string from nested ConstantPathNodes
      # Example: Types::Strict::String
      def build_constant_path(node)
        parts = []
        current = node

        while current.is_a?(Prism::ConstantPathNode)
          parts.unshift(current.name.to_s)
          current = current.parent
        end

        parts.unshift(current.name.to_s) if current.is_a?(Prism::ConstantReadNode)
        parts.join("::")
      end

      # Extract the receiver constant from a method call chain
      # Example: Types::String.constrained(format: /@/) → "Types::String"
      def extract_receiver_constant(node)
        receiver = node.receiver
        return unless receiver

        case receiver
        when Prism::ConstantReadNode, Prism::ConstantPathNode
          node_to_constant_string(receiver)
        when Prism::CallNode
          extract_receiver_constant(receiver)
        end
      end

      # ─────────────────────────────────────────────────────────────────────────
      # Type Mapping
      # ─────────────────────────────────────────────────────────────────────────

      # Map a type string to its corresponding Ruby type
      # Uses custom mappings from config (if available) merged with defaults
      def map_to_ruby_type(type_string)
        mappings = effective_type_mappings

        # Direct mapping lookup (custom mappings take precedence)
        return mappings[type_string] if mappings.key?(type_string)

        # Handle parameterized types: Types::Array.of(...) → Types::Array
        base_type = type_string.split(".").first
        mappings[base_type]
      end

      # Returns the effective type mappings (defaults + custom from config)
      # Custom mappings take precedence over defaults
      def effective_type_mappings
        return DEFAULT_TYPE_MAPPINGS unless defined?(Light::Services)
        return DEFAULT_TYPE_MAPPINGS unless Light::Services.respond_to?(:config)

        custom_mappings = Light::Services.config&.ruby_lsp_type_mappings
        return DEFAULT_TYPE_MAPPINGS if custom_mappings.nil? || custom_mappings.empty?

        DEFAULT_TYPE_MAPPINGS.merge(custom_mappings)
      rescue NoMethodError
        DEFAULT_TYPE_MAPPINGS
      end

      # ─────────────────────────────────────────────────────────────────────────
      # Method Registration
      # ─────────────────────────────────────────────────────────────────────────

      # Register all three generated methods for a field (getter, predicate, setter)
      def register_field_methods(field_name, location, ruby_type)
        register_getter(field_name, location, ruby_type)
        register_predicate(field_name, location)
        register_setter(field_name, location, ruby_type)
      end

      def register_getter(field_name, location, ruby_type)
        @listener.add_method(
          field_name.to_s,
          location,
          no_params_signature,
          comments: return_type_comment(ruby_type),
        )
      end

      def register_predicate(field_name, location)
        @listener.add_method(
          "#{field_name}?",
          location,
          no_params_signature,
          comments: "@return [Boolean]",
        )
      end

      def register_setter(field_name, location, ruby_type)
        @listener.add_method(
          "#{field_name}=",
          location,
          value_param_signature,
          comments: setter_comment(ruby_type),
        )
      end

      # ─────────────────────────────────────────────────────────────────────────
      # Signatures & Comments
      # ─────────────────────────────────────────────────────────────────────────

      def no_params_signature
        [RubyIndexer::Entry::Signature.new([])]
      end

      def value_param_signature
        [RubyIndexer::Entry::Signature.new([
          RubyIndexer::Entry::RequiredParameter.new(name: :value),
        ])]
      end

      def return_type_comment(ruby_type)
        return nil unless ruby_type

        "@return [#{ruby_type}]"
      end

      def setter_comment(ruby_type)
        return "@param value the value to set" unless ruby_type

        "@param value [#{ruby_type}] the value to set\n@return [#{ruby_type}]"
      end
    end
  end
end

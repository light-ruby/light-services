# frozen_string_literal: true

require_relative "type_mapper"

module Solargraph
  module LightServices
    # Solargraph Convention that generates virtual method pins for Light::Services DSL.
    # Handles `arg` and `output` declarations by creating getter, predicate, and setter methods.
    class Convention < Solargraph::Convention::Base
      # DSL methods that generate getter, predicate, and setter methods
      FIELD_DSL_METHODS = ["arg", "output"].freeze

      # Called when Solargraph needs file-specific pins (virtual code elements)
      # Parses the source for arg/output DSL calls and generates method pins
      #
      # @param source [Solargraph::Source] the source file being analyzed
      # @return [Solargraph::Environ] environment containing generated pins
      def local(source)
        pins = []
        return Solargraph::Environ.new(pins: pins) unless light_service_file?(source)

        # Parse the source to find arg and output calls
        ast = source.node
        return Solargraph::Environ.new(pins: pins) unless ast

        # Find all class definitions that might be Light::Services
        find_service_classes(ast, source) do |class_node, class_name, namespace|
          process_class_body(class_node, source, class_name, namespace, pins)
        end

        Solargraph::Environ.new(pins: pins)
      end

      private

      # Check if the file might contain Light::Services classes
      # @param source [Solargraph::Source]
      # @return [Boolean]
      def light_service_file?(source)
        source.code.include?("Light::Services") ||
          source.code.include?("ApplicationService") ||
          source.code.match?(/\b(arg|output)\s+:/)
      end

      # Recursively find class definitions in the AST
      # @param node [Parser::AST::Node]
      # @param source [Solargraph::Source]
      # @param namespace [String] current namespace path
      # @yield [class_node, class_name, namespace]
      def find_service_classes(node, source, namespace = "", &block)
        return unless node.is_a?(Parser::AST::Node)

        case node.type
        when :module
          mod_name = extract_const_name(node.children[0])
          new_namespace = namespace.empty? ? mod_name : "#{namespace}::#{mod_name}"
          node.children[1..].each { |child| find_service_classes(child, source, new_namespace, &block) }
        when :class
          class_name = extract_const_name(node.children[0])
          full_class_name = namespace.empty? ? class_name : "#{namespace}::#{class_name}"
          yield(node, full_class_name, namespace)
          # Also check for nested classes
          node.children[2..]&.each { |child| find_service_classes(child, source, full_class_name, &block) }
        when :begin, :block
          node.children.each { |child| find_service_classes(child, source, namespace, &block) }
        end
      end

      # Extract constant name from AST node
      # @param node [Parser::AST::Node]
      # @return [String]
      def extract_const_name(node)
        return "" unless node

        case node.type
        when :const
          parent_name = extract_const_name(node.children[0])
          name = node.children[1].to_s
          parent_name.empty? ? name : "#{parent_name}::#{name}"
        else
          ""
        end
      end

      # Process a class body to find arg and output DSL calls
      # @param class_node [Parser::AST::Node]
      # @param source [Solargraph::Source]
      # @param class_name [String]
      # @param namespace [String]
      # @param pins [Array<Solargraph::Pin::Base>]
      def process_class_body(class_node, source, class_name, namespace, pins)
        body = class_node.children[2]
        return unless body

        find_dsl_calls(body) do |_method_name, field_name, type_string, location|
          ruby_type = TypeMapper.resolve(type_string)
          generate_field_pins(source, class_name, namespace, field_name, ruby_type, location, pins)
        end
      end

      # Find arg and output DSL calls in the AST
      # @param node [Parser::AST::Node]
      # @yield [method_name, field_name, type_string, location]
      def find_dsl_calls(node, &block)
        return unless node.is_a?(Parser::AST::Node)

        case node.type
        when :send
          process_send_node(node, &block)
        when :begin, :block, :kwbegin
          node.children.each { |child| find_dsl_calls(child, &block) }
        end
      end

      # Process a send node to check if it's an arg or output call
      # @param node [Parser::AST::Node]
      # @yield [method_name, field_name, type_string, location]
      def process_send_node(node)
        receiver, method_name, *args = node.children
        return unless receiver.nil? # Only class-level calls (no receiver)
        return unless FIELD_DSL_METHODS.include?(method_name.to_s)
        return if args.empty?

        field_name = extract_symbol_value(args[0])
        return unless field_name

        type_string = extract_type_option(args[1..])
        location = node.location

        yield(method_name.to_s, field_name, type_string, location)
      end

      # Extract symbol value from AST node
      # @param node [Parser::AST::Node]
      # @return [String, nil]
      def extract_symbol_value(node)
        return unless node.is_a?(Parser::AST::Node)
        return unless node.type == :sym

        node.children[0].to_s
      end

      # Extract the type option from keyword arguments
      # @param args [Array<Parser::AST::Node>]
      # @return [String, nil]
      def extract_type_option(args)
        args.each do |arg|
          next unless arg.is_a?(Parser::AST::Node)

          case arg.type
          when :hash
            arg.children.each do |pair|
              next unless pair.type == :pair

              key, value = pair.children
              next unless key.type == :sym && key.children[0] == :type

              return node_to_type_string(value)
            end
          end
        end

        nil
      end

      # Convert an AST node representing a type to a string
      # @param node [Parser::AST::Node]
      # @return [String, nil]
      def node_to_type_string(node)
        return unless node.is_a?(Parser::AST::Node)

        case node.type
        when :const
          extract_const_name(node)
        when :send
          # Handle method chains like Types::String.constrained(...)
          extract_receiver_type(node)
        when :array
          # Handle array of types like [String, Integer]
          types = node.children.filter_map { |child| node_to_type_string(child) }
          types.join(", ") unless types.empty?
        end
      end

      # Extract the receiver type from a method chain
      # @param node [Parser::AST::Node]
      # @return [String, nil]
      def extract_receiver_type(node)
        receiver = node.children[0]
        return unless receiver

        case receiver.type
        when :const
          extract_const_name(receiver)
        when :send
          extract_receiver_type(receiver)
        end
      end

      # Generate getter, predicate, and setter pins for a field
      # @param source [Solargraph::Source]
      # @param class_name [String]
      # @param namespace [String]
      # @param field_name [String]
      # @param ruby_type [String, nil]
      # @param location [Parser::Source::Map]
      # @param pins [Array<Solargraph::Pin::Base>]
      def generate_field_pins(source, class_name, namespace, field_name, ruby_type, location, pins)
        closure = Solargraph::Pin::Namespace.new(
          name: class_name.split("::").last,
          closure: namespace.empty? ? nil : Solargraph::Pin::ROOT_PIN,
          location: Solargraph::Location.new(source.filename, Solargraph::Range.from_to(0, 0, 0, 0)),
        )

        # Getter method
        pins << create_method_pin(
          source: source,
          closure: closure,
          name: field_name,
          return_type: ruby_type,
          comments: getter_comments(field_name, ruby_type),
          location: location,
        )

        # Predicate method
        pins << create_method_pin(
          source: source,
          closure: closure,
          name: "#{field_name}?",
          return_type: "Boolean",
          comments: predicate_comments(field_name),
          location: location,
        )

        # Setter method (private)
        pins << create_method_pin(
          source: source,
          closure: closure,
          name: "#{field_name}=",
          return_type: ruby_type,
          comments: setter_comments(field_name, ruby_type),
          location: location,
          parameters: [Solargraph::Pin::Parameter.new(name: "value", decl: :arg)],
          visibility: :private,
        )
      end

      # Create a method pin
      # @param source [Solargraph::Source]
      # @param closure [Solargraph::Pin::Namespace]
      # @param name [String]
      # @param return_type [String, nil]
      # @param comments [String]
      # @param location [Parser::Source::Map]
      # @param parameters [Array<Solargraph::Pin::Parameter>]
      # @param visibility [Symbol]
      # @return [Solargraph::Pin::Method]
      def create_method_pin(source:, closure:, name:, return_type:, comments:, location:, parameters: [],
                            visibility: :public)
        loc = Solargraph::Location.new(
          source.filename,
          Solargraph::Range.from_to(
            location.line - 1,
            location.column,
            location.line - 1,
            location.column,
          ),
        )

        Solargraph::Pin::Method.new(
          closure: closure,
          name: name,
          comments: comments,
          scope: :instance,
          visibility: visibility,
          parameters: parameters,
          location: loc,
        )
      end

      # Generate YARD comments for getter method
      # @param field_name [String]
      # @param ruby_type [String, nil]
      # @return [String]
      def getter_comments(field_name, ruby_type)
        return "Returns the #{field_name} value" unless ruby_type

        "@return [#{ruby_type}] the #{field_name} value"
      end

      # Generate YARD comments for predicate method
      # @param field_name [String]
      # @return [String]
      def predicate_comments(field_name)
        "@return [Boolean] whether #{field_name} is present/truthy"
      end

      # Generate YARD comments for setter method
      # @param field_name [String]
      # @param ruby_type [String, nil]
      # @return [String]
      def setter_comments(_field_name, ruby_type)
        return "@param value the value to set\n@return the value" unless ruby_type

        "@param value [#{ruby_type}] the value to set\n@return [#{ruby_type}]"
      end
    end
  end
end

# frozen_string_literal: true

module Solargraph
  module LightServices
    # Maps dry-types and custom types to Ruby types for YARD documentation.
    # This provides Solargraph with accurate type information for code completion and hover.
    module TypeMapper
      # Default type mappings for common dry-types to their underlying Ruby types
      # These can be extended via Light::Services.config.solargraph_type_mappings
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
        "Types::Bool" => "Boolean",
        "Types::Strict::Bool" => "Boolean",
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
        "Types::Nil" => "nil",
        "Types::Strict::Nil" => "nil",
        "Types::Any" => "Object",
      }.freeze

      class << self
        # Resolve a type string to its Ruby type equivalent
        #
        # @param type_string [String, nil] the type string to resolve
        # @return [String, nil] the resolved Ruby type or nil if no mapping exists
        #
        # @example Resolve a dry-types type
        #   TypeMapper.resolve("Types::String") # => "String"
        #
        # @example Resolve a parameterized type
        #   TypeMapper.resolve("Types::Array.of(Types::String)") # => "Array"
        #
        # @example Pass through Ruby class names
        #   TypeMapper.resolve("User") # => "User"
        def resolve(type_string)
          return nil unless type_string

          mappings = effective_type_mappings

          # Direct mapping lookup (custom mappings take precedence)
          return mappings[type_string] if mappings.key?(type_string)

          # Handle parameterized types: Types::Array.of(...) → Types::Array
          base_type = type_string.split(".").first
          return mappings[base_type] if mappings.key?(base_type)

          # If it looks like a constant/class name, return as-is
          type_string if type_string.match?(/\A[A-Z]/)
        end

        private

        # Returns the effective type mappings (defaults + custom from config)
        # Custom mappings take precedence over defaults
        #
        # @return [Hash{String => String}] merged type mappings
        def effective_type_mappings
          return DEFAULT_TYPE_MAPPINGS unless defined?(Light::Services)
          return DEFAULT_TYPE_MAPPINGS unless Light::Services.respond_to?(:config)

          custom_mappings = Light::Services.config&.solargraph_type_mappings
          return DEFAULT_TYPE_MAPPINGS if custom_mappings.nil? || custom_mappings.empty?

          DEFAULT_TYPE_MAPPINGS.merge(custom_mappings)
        rescue NoMethodError
          DEFAULT_TYPE_MAPPINGS
        end
      end
    end
  end
end


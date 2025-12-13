# frozen_string_literal: true

module Light
  module Services
    class << self
      def configure
        yield config
      end

      def config
        @config ||= Config.new
      end
    end

    class Config
      DEFAULTS = {
        use_transactions: true,

        load_errors: true,
        break_on_error: true,
        raise_on_error: false,
        rollback_on_error: true,

        load_warnings: true,
        break_on_warning: false,
        raise_on_warning: false,
        rollback_on_warning: false,

        require_type: true,
      }.freeze

      attr_accessor(*DEFAULTS.keys)

      # Custom type mappings for Ruby LSP addon
      # Maps dry-types or custom types to Ruby types for hover/completion
      # Example: { "Types::UUID" => "String", "CustomTypes::Money" => "BigDecimal" }
      attr_accessor :ruby_lsp_type_mappings

      def initialize
        reset_to_defaults!
      end

      def reset_to_defaults!
        DEFAULTS.each { |key, value| public_send(:"#{key}=", value) }
        @ruby_lsp_type_mappings = {}
      end

      def to_h
        DEFAULTS.keys.to_h { |key| [key, public_send(key)] }.merge(
          ruby_lsp_type_mappings: ruby_lsp_type_mappings,
        )
      end

      def merge(config)
        to_h.merge(config)
      end
    end
  end
end

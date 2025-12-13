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
      # @return [Boolean] whether arguments and outputs must have a type specified
      attr_reader :require_type

      # @return [Boolean] whether to wrap service execution in a database transaction
      attr_reader :use_transactions

      # @return [Boolean] whether to copy errors to parent service in chain
      attr_reader :load_errors

      # @return [Boolean] whether to stop executing steps when an error is added
      attr_reader :break_on_error

      # @return [Boolean] whether to raise Light::Services::Error when service fails
      attr_reader :raise_on_error

      # @return [Boolean] whether to rollback the transaction when an error is added
      attr_reader :rollback_on_error

      # @return [Boolean] whether to copy warnings to parent service in chain
      attr_reader :load_warnings

      # @return [Boolean] whether to stop executing steps when a warning is added
      attr_reader :break_on_warning

      # @return [Boolean] whether to raise Light::Services::Error when service has warnings
      attr_reader :raise_on_warning

      # @return [Boolean] whether to rollback the transaction when a warning is added
      attr_reader :rollback_on_warning

      # @return [Hash{String => String}] custom type mappings for Ruby LSP addon.
      #   Maps dry-types or custom types to Ruby types for hover/completion.
      #   @example { "Types::UUID" => "String", "CustomTypes::Money" => "BigDecimal" }
      attr_reader :ruby_lsp_type_mappings

      DEFAULTS = {
        require_type: true,
        use_transactions: true,

        load_errors: true,
        break_on_error: true,
        raise_on_error: false,
        rollback_on_error: true,

        load_warnings: true,
        break_on_warning: false,
        raise_on_warning: false,
        rollback_on_warning: false,

        ruby_lsp_type_mappings: {}.freeze,
      }.freeze

      DEFAULTS.each_key do |name|
        define_method(:"#{name}=") do |value|
          instance_variable_set(:"@#{name}", value)
          @to_h = nil # Invalidate memoized hash
        end
      end

      def initialize
        reset_to_defaults!
      end

      def reset_to_defaults!
        DEFAULTS.each do |key, value|
          instance_variable_set(:"@#{key}", value)
        end

        @to_h = nil # Invalidate memoized hash
      end

      def to_h
        @to_h ||= DEFAULTS.keys.to_h do |key|
          [key, public_send(key)]
        end
      end

      def merge(config)
        to_h.merge(config)
      end
    end
  end
end

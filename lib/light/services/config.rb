# frozen_string_literal: true
# typed: strict

require "sorbet-runtime"

module Light
  module Services
    class << self
      extend T::Sig

      # Configure Light::Services with a block.
      #
      # @yield [Config] the configuration object
      # @return [void]
      #
      # @example
      #   Light::Services.configure do |config|
      #     config.require_arg_type = true
      #     config.require_output_type = true
      #     config.use_transactions = false
      #   end
      sig { params(_blk: T.proc.params(arg0: Config).void).void }
      def configure(&_blk)
        yield config
      end

      # Get the global configuration object.
      #
      # @return [Config] the configuration instance
      sig { returns(Config) }
      def config
        @config = T.let(@config, T.nilable(Config))
        @config ||= Config.new
      end
    end

    # Configuration class for Light::Services global settings.
    #
    # @example Accessing configuration
    #   Light::Services.config.require_arg_type # => true
    #
    # @example Modifying configuration
    #   Light::Services.config.use_transactions = false
    class Config
      extend T::Sig

      # @return [Boolean] whether arguments must have a type specified
      sig { returns(T::Boolean) }
      attr_accessor :require_arg_type

      # @return [Boolean] whether outputs must have a type specified
      sig { returns(T::Boolean) }
      attr_accessor :require_output_type

      # @return [Boolean] whether to wrap service execution in a database transaction
      sig { returns(T::Boolean) }
      attr_reader :use_transactions

      # @return [Boolean] whether to copy errors to parent service in chain
      sig { returns(T::Boolean) }
      attr_reader :load_errors

      # @return [Boolean] whether to stop executing steps when an error is added
      sig { returns(T::Boolean) }
      attr_reader :break_on_error

      # @return [Boolean] whether to raise Light::Services::Error when service fails
      sig { returns(T::Boolean) }
      attr_reader :raise_on_error

      # @return [Boolean] whether to rollback the transaction when an error is added
      sig { returns(T::Boolean) }
      attr_reader :rollback_on_error

      # @return [Boolean] whether to copy warnings to parent service in chain
      sig { returns(T::Boolean) }
      attr_reader :load_warnings

      # @return [Boolean] whether to stop executing steps when a warning is added
      sig { returns(T::Boolean) }
      attr_reader :break_on_warning

      # @return [Boolean] whether to raise Light::Services::Error when service has warnings
      sig { returns(T::Boolean) }
      attr_reader :raise_on_warning

      # @return [Boolean] whether to rollback the transaction when a warning is added
      sig { returns(T::Boolean) }
      attr_reader :rollback_on_warning

      # @return [Hash{String => String}] custom type mappings for Ruby LSP addon.
      #   Maps custom types to Ruby types for hover/completion.
      #   @example { "CustomTypes::UUID" => "String", "CustomTypes::Money" => "BigDecimal" }
      sig { returns(T::Hash[String, String]) }
      attr_reader :ruby_lsp_type_mappings

      DEFAULTS = T.let({
        require_arg_type: true,
        require_output_type: true,
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
      }.freeze, T::Hash[Symbol, T.untyped])

      DEFAULTS.each_key do |name|
        define_method(:"#{name}=") do |value|
          instance_variable_set(:"@#{name}", value)
          @to_h = T.let(nil, T.nilable(T::Hash[Symbol, T.untyped])) # Invalidate memoized hash
        end
      end

      # Convenience setter for backward compatibility.
      # Sets both require_arg_type and require_output_type.
      #
      # @param value [Boolean] whether to require types for arguments and outputs
      # @return [void]
      sig { params(value: T::Boolean).void }
      def require_type=(value)
        self.require_arg_type = value
        self.require_output_type = value
      end

      # Initialize configuration with default values.
      sig { void }
      def initialize # rubocop:disable Metrics/AbcSize
        @require_arg_type = T.let(true, T::Boolean)
        @require_output_type = T.let(true, T::Boolean)
        @use_transactions = T.let(true, T::Boolean)
        @load_errors = T.let(true, T::Boolean)
        @break_on_error = T.let(true, T::Boolean)
        @raise_on_error = T.let(false, T::Boolean)
        @rollback_on_error = T.let(true, T::Boolean)
        @load_warnings = T.let(true, T::Boolean)
        @break_on_warning = T.let(false, T::Boolean)
        @raise_on_warning = T.let(false, T::Boolean)
        @rollback_on_warning = T.let(false, T::Boolean)
        @ruby_lsp_type_mappings = T.let({}.freeze, T::Hash[String, String])
        @to_h = T.let(nil, T.nilable(T::Hash[Symbol, T.untyped]))

        reset_to_defaults!
      end

      # Reset all configuration options to their default values.
      #
      # @return [void]
      sig { void }
      def reset_to_defaults!
        DEFAULTS.each do |key, value|
          instance_variable_set(:"@#{key}", value)
        end

        @to_h = nil # Invalidate memoized hash
      end

      # Convert configuration to a hash.
      #
      # @return [Hash{Symbol => Object}] all configuration options as a hash
      sig { returns(T::Hash[Symbol, T.untyped]) }
      def to_h
        @to_h ||= T.let(
          DEFAULTS.keys.to_h do |key|
            [key, public_send(key)]
          end,
          T.nilable(T::Hash[Symbol, T.untyped]),
        )
      end

      # Merge configuration with additional options.
      #
      # @param config [Hash] options to merge
      # @return [Hash] merged configuration hash
      sig { params(config: T::Hash[Symbol, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
      def merge(config)
        to_h.merge(config)
      end
    end
  end
end

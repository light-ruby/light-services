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
      # Constants
      DEFAULTS = {
        use_transactions: true,

        load_errors: true,
        break_on_error: true,
        raise_on_error: false,
        rollback_on_error: true,

        load_warnings: true,
        break_on_warning: false,
        raise_on_warning: false,
        rollback_on_warning: false
      }.freeze

      # Getters / Setters
      attr_accessor :use_transactions,
                    :load_errors, :break_on_error, :raise_on_error, :rollback_on_error,
                    :load_warnings, :break_on_warning, :raise_on_warning, :rollback_on_warning

      def initialize
        reset_to_defaults!
      end

      def set(key, value)
        instance_variable_set("@#{key}", value)
      end

      def get(key)
        instance_variable_get("@#{key}")
      end

      def reset_to_defaults!
        DEFAULTS.each do |key, value|
          set(key, value)
        end
      end

      def to_h
        DEFAULTS.keys.map { |key| [key, get(key)] }.to_h
      end

      def merge(config)
        to_h.merge(config)
      end
    end
  end
end

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

        require_type: false,
      }.freeze

      attr_accessor(*DEFAULTS.keys)

      def initialize
        reset_to_defaults!
      end

      def reset_to_defaults!
        DEFAULTS.each { |key, value| public_send(:"#{key}=", value) }
      end

      def to_h
        DEFAULTS.keys.to_h { |key| [key, public_send(key)] }
      end

      def merge(config)
        to_h.merge(config)
      end
    end
  end
end

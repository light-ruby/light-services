# frozen_string_literal: true

module Light::Services
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
    DEFAULT_ARGS = {
      use_transactions: true,

      load_errors: true,
      load_warnings: true,

      break_on_error: true,
      raise_on_error: false,
      rollback_on_error: true,

      break_on_warning: false,
      raise_on_warning: false,
      rollback_on_warning: false
    }.freeze

    # Getters / Setters
    attr_accessor :load_errors, :use_transactions,
                  :break_on_error, :raise_on_error, :rollback_on_error,
                  :break_on_warning, :raise_on_warning, :rollback_on_warning

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
      DEFAULT_ARGS.each do |key, value|
        set(key, value)
      end
    end

    def to_h
      DEFAULT_ARGS.keys.map { |key| [key, get(key)] }.to_h
    end
  end
end

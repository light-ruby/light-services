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
      load_errors: true,
      use_transactions: true,
      rollback_on_error: true,
      raise_on_error: false
    }.freeze

    # Getters / Setters
    attr_accessor :load_errors, :use_transactions, :rollback_on_error, :raise_on_error

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
  end
end

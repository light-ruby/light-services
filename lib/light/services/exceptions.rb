# frozen_string_literal: true

module Light
  module Services
    class Error < StandardError; end
    class ArgTypeError < Error; end
    class ReservedNameError < Error; end
    class InvalidNameError < Error; end
    class NoStepsError < Error; end
    class MissingTypeError < Error; end

    # Backwards compatibility aliases (deprecated)
    NoStepError = Error
    TwoConditions = Error
  end
end

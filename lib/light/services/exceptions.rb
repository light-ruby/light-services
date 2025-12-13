# frozen_string_literal: true

module Light
  module Services
    class Error < StandardError; end
    class ArgTypeError < Error; end
    class ReservedNameError < Error; end
    class InvalidNameError < Error; end
    class NoStepsError < Error; end
    class MissingTypeError < Error; end

    # Control flow exception for stop_immediately!
    # Not an error - used to halt execution gracefully
    class StopExecution < StandardError; end

    # Backwards compatibility aliases (deprecated)
    NoStepError = Error
    TwoConditions = Error
  end
end

# frozen_string_literal: true

module Light
  module Services
    class Error < StandardError; end
    class NoStepError < Error; end
    class ArgTypeError < Error; end
    class TwoConditions < Error; end
  end
end

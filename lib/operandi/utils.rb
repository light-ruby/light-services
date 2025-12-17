# frozen_string_literal: true

module Operandi
  # Utility module providing helper methods for the Operandi library
  module Utils
    module_function

    # Creates a deep copy of an object to prevent mutation of shared references.
    #
    # @param object [Object] the object to duplicate
    # @return [Object] a deep copy of the object
    #
    # @example Deep duping a hash
    #   original = { a: { b: 1 } }
    #   copy = Utils.deep_dup(original)
    #   copy[:a][:b] = 2
    #   original[:a][:b] # => 1
    #
    # @example Deep duping an array
    #   original = [[1, 2], [3, 4]]
    #   copy = Utils.deep_dup(original)
    #   copy[0] << 5
    #   original[0] # => [1, 2]
    #
    def deep_dup(object)
      # Use ActiveSupport's deep_dup if available (preferred for Rails apps)
      return object.deep_dup if object.respond_to?(:deep_dup)

      # Fallback to Marshal for objects that support serialization
      Marshal.load(Marshal.dump(object))
    rescue TypeError
      # Last resort: use dup if available, otherwise return original
      object.respond_to?(:dup) ? object.dup : object
    end
  end
end

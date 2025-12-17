# frozen_string_literal: true

module Operandi
  # Represents a single error or warning message.
  #
  # @example Creating a message
  #   message = Message.new(:name, "can't be blank", break: true)
  #   message.key    # => :name
  #   message.text   # => "can't be blank"
  #   message.break? # => true
  class Message
    # @return [Symbol] the key/field this message belongs to
    attr_reader :key

    # @return [String] the message text
    attr_reader :text

    # Create a new message.
    #
    # @param key [Symbol] the key/field this message belongs to
    # @param text [String] the message text
    # @param opts [Hash] additional options
    # @option opts [Boolean] :break whether to stop step execution
    # @option opts [Boolean] :rollback whether to rollback the transaction
    def initialize(key, text, opts = {})
      @key = key
      @text = text
      @opts = opts
    end

    # Check if this message should stop step execution.
    #
    # @return [Boolean] true if break option was set
    def break?
      @opts[:break]
    end

    # Check if this message should trigger a transaction rollback.
    #
    # @return [Boolean] true if rollback option was set
    def rollback?
      @opts[:rollback]
    end

    # Return the message text.
    #
    # @return [String] the message text
    def to_s
      text
    end
  end
end

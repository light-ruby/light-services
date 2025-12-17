# frozen_string_literal: true
# typed: strict

require "sorbet-runtime"

module Light
  module Services
    # Represents a single error or warning message.
    #
    # @example Creating a message
    #   message = Message.new(:name, "can't be blank", break: true)
    #   message.key    # => :name
    #   message.text   # => "can't be blank"
    #   message.break? # => true
    class Message
      extend T::Sig

      # @return [Symbol] the key/field this message belongs to
      sig { returns(Symbol) }
      attr_reader :key

      # @return [String] the message text
      sig { returns(String) }
      attr_reader :text

      # Create a new message.
      #
      # @param key [Symbol] the key/field this message belongs to
      # @param text [String] the message text
      # @param opts [Hash] additional options
      # @option opts [Boolean] :break whether to stop step execution
      # @option opts [Boolean] :rollback whether to rollback the transaction
      sig { params(key: Symbol, text: String, opts: T::Hash[Symbol, T.untyped]).void }
      def initialize(key, text, opts = {})
        @key = T.let(key, Symbol)
        @text = T.let(text, String)
        @opts = T.let(opts, T::Hash[Symbol, T.untyped])
      end

      # Check if this message should stop step execution.
      #
      # @return [Boolean] true if break option was set
      sig { returns(T.untyped) }
      def break?
        @opts[:break]
      end

      # Check if this message should trigger a transaction rollback.
      #
      # @return [Boolean] true if rollback option was set
      sig { returns(T.untyped) }
      def rollback?
        @opts[:rollback]
      end

      # Return the message text.
      #
      # @return [String] the message text
      sig { returns(String) }
      def to_s
        text
      end
    end
  end
end

# frozen_string_literal: true

# This class stores errors and warnings
module Light
  module Services
    class Message
      # Getters
      attr_reader :key, :text

      def initialize(key, text, opts = {})
        @key = key
        @text = text
        @opts = opts
      end

      def break?
        @opts[:break]
      end

      def rollback?
        @opts[:rollback]
      end

      def to_s
        text
      end
    end
  end
end

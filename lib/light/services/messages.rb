# frozen_string_literal: true

module Light
  module Services
    class Messages
      # Includes
      extend Forwardable

      # Settings
      def_delegators :@messages, :any?, :empty?, :each

      def initialize(config)
        @break = false
        @config = config
        @messages = {}
      end

      def add(key, message, break_execution: nil, rollback: nil)
        @messages[key] ||= []
        @messages[key] << message

        @break = true if (break_execution.nil? ? @config[:break_on_add] : break_execution)

        raise ActiveRecord::Rollback if defined?(ActiveRecord::Rollback) && (rollback.nil? ? @config[:rollback_on_add] : rollback)
        raise Light::Services::Error, "#{key.to_s.capitalize} #{message}" if @config[:raise_on_add]
      end

      def break?
        @break
      end

      def from(messages)
        if messages.respond_to?(:each)
          messages.each do |key, message|
            add(key, message)
          end
        else
          # TODO: Update error
          raise Light::Services::Error
        end
      end
    end
  end
end

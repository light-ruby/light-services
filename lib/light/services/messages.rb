# frozen_string_literal: true

# This class stores errors and warnings
module Light
  module Services
    class Messages
      def initialize(config)
        @break = false
        @config = config
        @messages = {}
      end

      def add(key, message, break_execution: nil, rollback: nil)
        @messages[key] ||= []

        if message.is_a?(Array)
          @messages[key] += message
        else
          @messages[key] << message
        end

        break!(break_execution)
        raise!(key, message)
        rollback!(rollback)
      end

      def break?
        @break
      end

      def from(entity, break_execution: nil, rollback: nil)
        if defined?(ActiveRecord::Base) && entity.is_a?(ActiveRecord::Base)
          from(entity.errors.messages, break_execution: break_execution, rollback: rollback)
        elsif entity.respond_to?(:each)
          entity.each do |key, message|
            add(key, message, break_execution: break_execution, rollback: rollback)
          end
        else
          # TODO: Update error
          raise Light::Services::Error
        end
      end

      def method_missing(method, *args, &block)
        if @messages.respond_to?(method)
          @messages.public_send(method, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(method, include_private = false)
        @messages.respond_to?(method, include_private) || super
      end

      private

      def break!(break_execution)
        return unless break_execution.nil? ? @config[:break_on_add] : break_execution

        @break = true
      end

      def raise!(key, message)
        return unless @config[:raise_on_add]

        raise Light::Services::Error, "#{key.to_s.capitalize} #{message}"
      end

      def rollback!(rollback)
        return if !defined?(ActiveRecord::Rollback) || !(rollback.nil? ? @config[:rollback_on_add] : rollback)

        raise ActiveRecord::Rollback
      end
    end
  end
end

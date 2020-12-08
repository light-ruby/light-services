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

      def add(key, message, opts = {})
        @messages[key] ||= []

        if message.is_a?(Array)
          @messages[key] += message
        else
          @messages[key] << message
        end

        raise!(key, message)
        break!(opts[:break])
        rollback!(opts[:rollback])
      end

      def break?
        @break
      end

      def copy_from(entity, opts = {})
        if defined?(ActiveRecord::Base) && entity.is_a?(ActiveRecord::Base)
          copy_from(entity.errors.messages, opts)
        elsif entity.respond_to?(:each)
          entity.each do |key, message|
            add(key, message, opts)
          end
        else
          # TODO: Update error
          raise Light::Services::Error
        end
      end

      def copy_to(entity)
        if defined?(ActiveRecord::Base) && entity.is_a?(ActiveRecord::Base)
          each do |key, message|
            entity.errors.add(key, message)
          end
        elsif entity.is_a?(Hash)
          each do |key, message|
            entity[key] ||= []
            entity[key] << message
          end
        else
          # TODO: Update error
          raise Light::Services::Error
        end

        entity
      end

      def errors_to_record(record)
        if !defined?(ActiveRecord::Base) || !record.is_a?(ActiveRecord::Base)
          # TODO: Update error
          raise Light::Services::Error
        end

        errors.each do |key, message|
          record.errors.add(key, message)
        end

        record
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

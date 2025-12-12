# frozen_string_literal: true

# This class stores errors and warnings
module Light
  module Services
    class Messages
      extend Forwardable

      def_delegators :@messages, :[], :any?, :empty?, :size, :keys, :values, :each, :each_with_index, :key?
      alias has_key? key?

      def initialize(config)
        @break = false
        @config = config
        @messages = {}
      end

      # Returns total count of all messages across all keys
      def count
        @messages.values.sum(&:size)
      end

      def add(key, texts, opts = {})
        raise Light::Services::Error, "Error must be a non-empty string" unless texts

        message = nil

        [*texts].each do |text|
          message = text.is_a?(Message) ? text : Message.new(key, text, opts)

          raise Light::Services::Error, "Error must be a non-empty string" unless valid_error_text?(message.text)

          @messages[key] ||= []
          @messages[key] << message
        end

        raise!(message)
        break!(opts.key?(:break) ? opts[:break] : message.break?)
        rollback!(opts.key?(:rollback) ? opts[:rollback] : message.rollback?) if !opts.key?(:last) || opts[:last]
      end

      def break?
        @break
      end

      def copy_from(entity, opts = {})
        if defined?(ActiveRecord::Base) && entity.is_a?(ActiveRecord::Base)
          copy_from(entity.errors.messages, opts)
        elsif entity.is_a?(Light::Services::Base)
          copy_from(entity.errors, opts)
        elsif entity.respond_to?(:each)
          last_index = entity.size - 1

          entity.each_with_index do |(key, message), index|
            add(key, message, opts.merge(last: index == last_index))
          end
        else
          raise Light::Services::Error, "Don't know how to import errors from #{entity}"
        end
      end
      alias from_record copy_from

      def to_h
        @messages.to_h.transform_values { |value| value.map(&:to_s) }
      end

      private

      def valid_error_text?(text)
        return false unless text.is_a?(String)

        !text.strip.empty?
      end

      def break!(break_execution)
        return unless break_execution.nil? ? @config[:break_on_add] : break_execution

        @break = true
      end

      def raise!(message)
        return unless @config[:raise_on_add]

        raise Light::Services::Error, "#{message.key.to_s.capitalize} #{message}"
      end

      def rollback!(rollback)
        return if !defined?(ActiveRecord::Rollback) || !(rollback.nil? ? @config[:rollback_on_add] : rollback)

        raise ActiveRecord::Rollback
      end
    end
  end
end

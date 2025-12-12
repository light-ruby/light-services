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

      def add(key, texts, opts = {})
        raise Light::Services::Error, "Error text can't be blank" if !texts || texts.blank?

        message = nil

        [*texts].each do |text|
          message = text.is_a?(Message) ? text : Message.new(key, text, opts)

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

      def copy_to(entity)
        if (defined?(ActiveRecord::Base) && entity.is_a?(ActiveRecord::Base)) || entity.is_a?(Light::Services::Base)
          each do |key, messages|
            messages.each do |message|
              entity.errors.add(key, message.to_s)
            end
          end
        elsif entity.is_a?(Hash)
          each do |key, messages|
            entity[key] ||= []
            entity[key] += messages.map(&:to_s)
          end
        else
          raise Light::Services::Error, "Don't know how to export errors to #{entity}"
        end

        entity
      end

      def to_h
        @messages.to_h.transform_values { |value| value.map(&:to_s) }
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

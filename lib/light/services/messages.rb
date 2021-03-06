# frozen_string_literal: true

module Light
  module Services
    class Messages
      def initialize
        @storage = {}
      end

      def add(key, message, rollback: true)
        storage[key] ||= []
        storage[key] << message

        rollback! if rollback
      end

      def from_record(record, rollback: true)
        return unless record.errors.any?

        record.errors.messages.each do |key, messages|
          messages.each do |message|
            add(key, message, rollback: false)
          end
        end

        rollback! if rollback
      end

      def from_service(service, rollback: true)
        return unless service.errors.any?

        service.errors.each do |key, message|
          add(key, message, rollback: false)
        end

        rollback! if rollback
      end

      def delete(key)
        storage.delete(key)
      end

      def blank?
        storage.empty?
      end

      def any?
        !blank?
      end

      def to_hash
        storage
      end

      def flatten
        to_hash.flat_map do |key, messages|
          messages.map do |message|
            [key, message]
          end
        end
      end

      def each
        flatten.each do |key, message|
          yield key, message
        end
      end

      alias to_h to_hash

      private

      # Getters / Setters
      attr_accessor :storage

      def rollback!
        raise ActiveRecord::Rollback if defined?(ActiveRecord::Rollback)
      end
    end
  end
end

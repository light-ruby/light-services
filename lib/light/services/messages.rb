# frozen_string_literal: true

module Light
  module Services
    class Messages
      def initialize
        @storage = {}
      end

      def add(key, message)
        storage[key] ||= []
        storage[key] << message
      end

      def from_record(record)
        record.errors.to_h.each do |key, message|
          add(key, message)
        end
      end

      def from_service(service)
        service.errors.each do |key, message|
          add(key, message)
        end
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

      # Getters/Setters
      attr_accessor :storage
    end
  end
end

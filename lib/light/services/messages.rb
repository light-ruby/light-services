module Light
  module Services
    class Messages
      def initialize
        @storage = {}
      end

      def add(key, message)
        @storage[key] ||= []
        @storage[key] << message
      end

      def from_record(record)
        record.errors.to_h.each do |key, value|
          add(key, value)
        end
      end

      def delete(key)
        @storage.delete(key)
      end

      def blank?
        @storage.empty?
      end

      def any?
        !blank?
      end

      def to_hash
        @storage
      end

      private

      # Getters/Setters
      attr_accessor :storage
    end
  end
end

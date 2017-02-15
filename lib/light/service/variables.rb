module Light
  module Service
    class Variables
      def initialize
        @storage = {}
      end

      def add(key, variable)
        @storage[key] = variable
      end

      def get(key)
        @storage[key]
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

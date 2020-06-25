# frozen_string_literal: true

module Light
  module Services
    class Collection
      def initialize(klass)
        @klass = klass
        @collection = []
      end

      def add(name, opts = {})
        @collection << @klass.new(name, opts)
      end

      def insert(item)
        @collection << item
      end
    end
  end
end

# frozen_string_literal: true

module Light
  module Services
    class ClassBasedCollection < Collection
      def initialize(klass)
        @klass = klass
        @collection = {}
      end

      def add(klass, name, opts = {})
        @collection[klass] ||= all_from_superclass(klass).dup
        item = @klass.new(name, klass, opts)

        # TODO: Remove duplication
        if opts[:before]
          index = @collection[klass].index { |find_item| find_item.name == opts[:before] }

          # TODO: Update error
          raise Light::Services::Error unless index

          @collection[klass].insert(index, item)
        elsif opts[:after]
          index = @collection[klass].index { |find_item| find_item.name == opts[:after] }

          # TODO: Update error
          raise Light::Services::Error unless index

          @collection[klass].insert(index + 1, item)
        else
          @collection[klass] << item
        end
      end

      def remove(klass, name)
        @collection[klass] ||= all_from_superclass(klass).dup
        @collection[klass].delete_if { |item| item.name == name }
      end

      def all(klass)
        @collection[klass] || all_from_superclass(klass)
      end

      private

      def all_from_superclass(klass)
        if klass.superclass <= Light::Services::Base
          all(klass.superclass)
        else
          []
        end
      end
    end
  end
end

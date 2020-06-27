# frozen_string_literal: true

module Light
  module Services
    module ClassBasedCollection
      class Base
        def initialize(item_class)
          @item_class = item_class
          @collection = {}
        end

        def add(klass, name, opts = {})
          @collection[klass] ||= all_from_superclass(klass).dup

          item = @item_class.new(name, klass, opts)

          if opts[:before]
            add_before(klass, opts[:before], item)
          elsif opts[:after]
            add_after(klass, opts[:after], item)
          else
            @collection[klass] << item
          end
        end

        def add_after(klass, after_name, item)
          index = find_index(klass, after_name)

          unless index
            raise Light::Services::NoStepError, "Cannot find step `#{after_name}` in service `#{klass}`"
          end

          @collection[klass].insert(index, item)
        end

        def add_before(klass, before_name, item)
          index = find_index(klass, before_name)

          unless index
            raise Light::Services::NoStepError, "Cannot find step `#{before_name}` in service `#{klass}`"
          end

          @collection[klass].insert(index + 1, item)
        end

        def find_index(klass, name)
          @collection[klass].index { |find_item| find_item.name == name }
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
end

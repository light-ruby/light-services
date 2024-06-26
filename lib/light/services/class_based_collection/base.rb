# frozen_string_literal: true

# Create class based collections for storing arguments settings, steps settings and outputs settings
#
# General functionality:
#   1. Collection automatically loads data from parent classes
#   2. It's possible to redefine items if needed (e.g. arguments)
#   3. We can add items into collection after or before another items
#
module Light
  module Services
    module ClassBasedCollection
      class Base
        # TODO: Add `prepend: true`
        def initialize(item_class, allow_redefine)
          @item_class = item_class
          @allow_redefine = allow_redefine
          @collection = {}
        end

        def add(klass, name, opts = {})
          @collection[klass] ||= all_from_superclass(klass)

          validate_name!(klass, name)
          validate_opts!(klass, name, opts)

          item = @item_class.new(name, klass, opts)

          if opts[:before] || opts[:after]
            insert_item(klass, name, opts, item)
          else
            @collection[klass][name] = item
          end
        end

        def find_index(klass, name)
          index = @collection[klass].keys.index(name)

          return index if index

          # TODO: Update `NoStepError` because it maybe not only step
          raise Light::Services::NoStepError, "Cannot find #{@item_class} `#{name}` in service #{klass}"
        end

        def remove(klass, name)
          @collection[klass] ||= all_from_superclass(klass)
          @collection[klass].delete(name)
        end

        def all(klass)
          @collection[klass] || all_from_superclass(klass)
        end

        private

        def all_from_superclass(klass)
          if klass.superclass <= Light::Services::Base
            all(klass.superclass).dup
          else
            {}
          end
        end

        def validate_name!(klass, name)
          if !@allow_redefine && all(klass).key?(name)
            raise Light::Services::Error, "#{@item_class} with name `#{name}` already exists in service #{klass}"
          end
        end

        def validate_opts!(klass, name, opts)
          if opts[:before] && opts[:after]
            raise Light::Services::Error, "You cannot specify `before` and `after` " \
                                          "for #{@item_class} `#{name}` in service #{klass} at the same time"
          end
        end

        def insert_item(klass, name, opts, item)
          index = find_index(klass, opts[:before] || opts[:after])
          index += 1 unless opts[:before]

          @collection[klass] = @collection[klass].to_a.insert(index, [name, item]).to_h
        end
      end
    end
  end
end

# frozen_string_literal: true

module Light
  module Services
    module ClassBasedCollection
      class Base
        def initialize(item_class, allow_redefine)
          @item_class = item_class
          @allow_redefine = allow_redefine
          @collection = {}
        end

        def add(klass, name, opts = {})
          @collection[klass] ||= all_from_superclass(klass)

          if !@allow_redefine && all(klass).keys.include?(name)
            # TODO: Update error class
            raise Light::Services::Error, "#{@item_class} with name `#{name}` already exists in service #{klass}"
          end

          if opts[:before] && opts[:after]
            # TODO: Update error class
            raise Light::Services::Error, "You cannot specify `before` and `after` for #{@item_class} `#{name}` in service #{klass} at the same time"
          end

          item = @item_class.new(name, klass, opts)

          if opts[:before] || opts[:after]
            index = find_index(klass, opts[:before] || opts[:after])
            index = opts[:before] ? index : index + 1

            @collection[klass] = @collection[klass].to_a.insert(index, [name, item]).to_h
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
      end
    end
  end
end

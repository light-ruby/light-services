# frozen_string_literal: true

module Light
  module Services
    module ClassBasedCollection
      module Mount
        def mount_class_based_collection(collection_name, klass:, shortcut:, allow_redefine: false)
          class_variable_set("@@#{collection_name}", ClassBasedCollection::Base.new(klass, allow_redefine))

          define_singleton_method shortcut do |item_name, opts = {}|
            collection = class_variable_get("@@#{collection_name}")
            collection.add(self, item_name, opts)
          end

          define_singleton_method "remove_#{shortcut}" do |item_name|
            collection = class_variable_get("@@#{collection_name}")
            collection.remove(self, item_name)
          end

          define_singleton_method collection_name do
            collection = class_variable_get("@@#{collection_name}")
            collection.all(self)
          end
        end
      end
    end
  end
end

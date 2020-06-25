# frozen_string_literal: true

module Light
  module Services
    module MountCollection
      def mount_collection(collection_name, klass:, singular:)
        class_variable_set("@@#{collection_name}", ClassBasedCollection.new(klass))

        define_singleton_method singular do |item_name, opts = {}|
          collection = class_variable_get("@@#{collection_name}")
          collection.add(self, item_name, opts)
        end

        define_singleton_method "remove_#{singular}" do |item_name|
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

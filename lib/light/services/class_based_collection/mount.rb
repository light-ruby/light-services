# frozen_string_literal: true

# This class allows to mount class based collections to service objects
#
# Usage:
#
#   mount_class_based_collection :steps,     klass: Settings::Step,     shortcut: :step
#   mount_class_based_collection :outputs,   klass: Settings::Output,   shortcut: :output
#   mount_class_based_collection :arguments, klass: Settings::Argument, shortcut: :arg, allow_redefine: true
#
module Light
  module Services
    module ClassBasedCollection
      module Mount
        def mount_class_based_collection(collection_name, item_class:, shortcut:, allow_redefine: false)
          class_variable_set(:"@@#{collection_name}", ClassBasedCollection::Base.new(item_class, allow_redefine))

          define_singleton_method shortcut do |item_name, opts = {}|
            class_variable_get(:"@@#{collection_name}").add(self, item_name, opts)
          end

          define_singleton_method :"remove_#{shortcut}" do |item_name|
            class_variable_get(:"@@#{collection_name}").remove(self, item_name)
          end

          define_singleton_method collection_name do
            class_variable_get(:"@@#{collection_name}").all(self)
          end
        end
      end
    end
  end
end

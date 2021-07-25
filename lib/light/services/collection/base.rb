# frozen_string_literal: true

# Collection to store arguments and outputs values
module Light
  module Services
    module Collection
      class Base
        # Includes
        extend Forwardable

        # Settings
        def_delegators :@storage, :key?, :to_h

        def initialize(instance, storage = {})
          @instance = instance
          @storage = storage

          return if storage.is_a?(Hash)

          raise Light::Services::ArgTypeError, "#{instance.class} - arguments must be a Hash"
        end

        def set(key, value)
          @storage[key] = value
        end

        def get(key)
          @storage[key]
        end

        def [](key)
          get(key)
        end

        def []=(key, value)
          set(key, value)
        end

        def load_defaults
          settings_collection.each do |name, settings|
            next if !settings.default_exists || key?(name)

            set(name, deep_dup(settings.default))
          end
        end

        private

        def deep_dup(object)
          Marshal.load(Marshal.dump(object))
        end
      end
    end
  end
end

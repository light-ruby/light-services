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


        def load_defaults
          settings_collection.select(&:default_exists).each do |settings|
            next if key?(settings.name)

            set(settings.name, settings.default)
          end
        end

        private

        def settings_collection
          raise NotImplementedError
        end
      end
    end
  end
end

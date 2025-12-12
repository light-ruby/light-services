# frozen_string_literal: true

require_relative "constants"

# Collection to store arguments and outputs values
module Light
  module Services
    module Collection
      class Base
        extend Forwardable

        def_delegators :@storage, :key?, :to_h

        def initialize(instance, collection_type, storage = {})
          validate_collection_type!(collection_type)

          @instance = instance
          @collection_type = collection_type
          @storage = storage

          return if storage.is_a?(Hash)

          raise Light::Services::ArgTypeError, "#{instance.class} - #{collection_type} must be a Hash"
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

            if settings.default.is_a?(Proc)
              set(name, @instance.instance_exec(&settings.default))
            else
              set(name, Utils.deep_dup(settings.default))
            end
          end
        end

        def validate!
          settings_collection.each do |name, field|
            next if field.optional && (!key?(name) || get(name).nil?)

            # validate_type! returns the (possibly coerced) value
            coerced_value = field.validate_type!(get(name))
            # Store the coerced value back (supports dry-types coercion)
            set(name, coerced_value) if coerced_value != get(name)
          end
        end

        # Extend args with context values (only for arguments)
        def extend_with_context(args)
          return args unless @collection_type == CollectionTypes::ARGUMENTS

          settings_collection.each do |name, field|
            next if !field.context || args.key?(name) || !key?(name)

            args[field.name] = get(name)
          end

          args
        end

        private

        def validate_collection_type!(type)
          return if CollectionTypes::ALL.include?(type)

          raise ArgumentError,
                "collection_type must be one of #{CollectionTypes::ALL.join(', ')}, got: #{type.inspect}"
        end

        def settings_collection
          @instance.class.public_send(@collection_type)
        end
      end

      # Aliases for backwards compatibility
      Arguments = Base
      Outputs = Base
    end
  end
end

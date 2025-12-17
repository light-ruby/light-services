# frozen_string_literal: true
# typed: true

require "forwardable"
require_relative "constants"
require "sorbet-runtime"

module Light
  module Services
    # Collection module for storing argument and output values.
    module Collection
      # Storage for service arguments or outputs with type validation.
      #
      # @example Accessing values
      #   service.arguments[:name]  # => "John"
      #   service.outputs[:user]    # => #<User id: 1>
      class Base
        extend T::Sig
        extend Forwardable

        # @!method key?(key)
        #   Check if a key exists in the collection.
        #   @param key [Symbol] the key to check
        #   @return [Boolean] true if key exists

        # @!method to_h
        #   Convert collection to a hash.
        #   @return [Hash] the stored values
        def_delegators :@storage, :key?, :to_h

        # Initialize a new collection.
        #
        # @param instance [Base] the service instance
        # @param collection_type [String] "arguments" or "outputs"
        # @param storage [Hash] initial values
        # @raise [ArgTypeError] if storage is not a Hash
        sig { params(instance: T.untyped, collection_type: Symbol, storage: T.untyped).void }
        def initialize(instance, collection_type, storage = {})
          validate_collection_type!(collection_type)

          @instance = T.let(instance, T.untyped)
          @collection_type = T.let(collection_type, Symbol)

          unless storage.is_a?(Hash)
            raise Light::Services::ArgTypeError, "#{instance.class} - #{collection_type} must be a Hash"
          end

          @storage = T.let(storage, T::Hash[Symbol, T.untyped])
        end

        # Set a value in the collection.
        #
        # @param key [Symbol] the key to set
        # @param value [Object] the value to store
        # @return [Object] the stored value
        sig { params(key: Symbol, value: T.untyped).returns(T.untyped) }
        def set(key, value)
          @storage[key] = value
        end

        # Get a value from the collection.
        #
        # @param key [Symbol] the key to retrieve
        # @return [Object, nil] the stored value or nil
        sig { params(key: Symbol).returns(T.untyped) }
        def get(key)
          @storage[key]
        end

        # Get a value using bracket notation.
        #
        # @param key [Symbol] the key to retrieve
        # @return [Object, nil] the stored value or nil
        sig { params(key: Symbol).returns(T.untyped) }
        def [](key)
          get(key)
        end

        # Set a value using bracket notation.
        #
        # @param key [Symbol] the key to set
        # @param value [Object] the value to store
        # @return [Object] the stored value
        sig { params(key: Symbol, value: T.untyped).returns(T.untyped) }
        def []=(key, value)
          set(key, value)
        end

        # Load default values for fields that haven't been set.
        #
        # @return [void]
        sig { void }
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

        # Validate all values against their type definitions.
        #
        # @return [void]
        # @raise [ArgTypeError] if a value fails type validation
        sig { void }
        def validate!
          settings_collection.each do |name, field|
            next if field.optional && (!key?(name) || get(name).nil?)

            # validate_type! returns the validated value
            validated_value = field.validate_type!(get(name))
            # Store the validated value back
            set(name, validated_value) if validated_value != get(name)
          end
        end

        # Extend arguments hash with context values from this collection.
        # Only applies to arguments collections.
        #
        # @param args [Hash] arguments hash to extend
        # @return [Hash] the extended arguments hash
        sig { params(args: T::Hash[Symbol, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
        def extend_with_context(args)
          return args unless @collection_type == CollectionTypes::ARGUMENTS

          settings_collection.each do |name, field|
            next if !field.context || args.key?(name) || !key?(name)

            args[field.name] = get(name)
          end

          args
        end

        private

        sig { params(type: Symbol).void }
        def validate_collection_type!(type)
          return if CollectionTypes::ALL.include?(type)

          raise ArgumentError,
                "collection_type must be one of #{CollectionTypes::ALL.join(', ')}, got: #{type.inspect}"
        end

        sig { returns(T::Hash[Symbol, T.untyped]) }
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

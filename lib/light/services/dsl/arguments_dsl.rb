# typed: strict
# frozen_string_literal: true

require_relative "../constants"
require_relative "validation"
require "sorbet-runtime"

module Light
  module Services
    module Dsl
      # DSL for defining and managing service arguments
      module ArgumentsDsl
        extend T::Sig

        sig { params(base: T.untyped).void }
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          extend T::Sig

          # Define an argument for the service
          #
          # @param name [Symbol] the argument name
          # @param opts [Hash] options for configuring the argument
          # @option opts [Class, Array<Class>] :type Type(s) to validate against
          #   (e.g., String, Integer, [String, Symbol])
          # @option opts [Boolean] :optional (false) Whether nil values are allowed
          # @option opts [Object, Proc] :default Default value or proc to evaluate in instance context
          # @option opts [Boolean] :context (false) Whether to pass this argument to child services
          #
          # @example Define a required string argument
          #   arg :name, type: String
          #
          # @example Define an optional argument with default
          #   arg :age, type: Integer, optional: true, default: 25
          #
          # @example Define an argument with multiple allowed types
          #   arg :id, type: [String, Integer]
          #
          # @example Define an argument with proc default
          #   arg :timestamp, type: Time, default: -> { Time.now }
          #
          # @example Define a context argument passed to child services
          #   arg :current_user, type: User, context: true
          sig { params(name: T.untyped, opts: T::Hash[Symbol, T.untyped]).void }
          def arg(name, opts = {})
            Validation.validate_symbol_name!(name, :argument, self)
            Validation.validate_reserved_name!(name, :argument, self)
            Validation.validate_name_conflicts!(name, :argument, self)
            Validation.validate_type_required!(name, :argument, self, opts)

            own_arguments[T.cast(name, Symbol)] = Settings::Field.new(name, self, opts.merge(field_type: FieldTypes::ARGUMENT))
            @arguments = T.let(nil, T.nilable(T::Hash[Symbol, Settings::Field]))
          end

          # Remove an argument from the service
          #
          # @param name [Symbol] the argument name to remove
          sig { params(name: Symbol).void }
          def remove_arg(name)
            own_arguments.delete(name)
            @arguments = T.let(nil, T.nilable(T::Hash[Symbol, Settings::Field]))
          end

          # Get all arguments including inherited ones
          #
          # @return [Hash] all arguments defined for this service
          sig { returns(T::Hash[Symbol, Settings::Field]) }
          def arguments
            @arguments = T.let(@arguments, T.nilable(T::Hash[Symbol, Settings::Field]))
            @arguments ||= build_arguments
          end

          # Get only arguments defined in this class
          #
          # @return [Hash] arguments defined in this class only
          sig { returns(T::Hash[Symbol, Settings::Field]) }
          def own_arguments
            @own_arguments = T.let(@own_arguments, T.nilable(T::Hash[Symbol, Settings::Field]))
            @own_arguments ||= {}
          end

          private

          # Build arguments by merging inherited arguments with own arguments
          #
          # @return [Hash] merged arguments
          sig { returns(T::Hash[Symbol, Settings::Field]) }
          def build_arguments
            inherited = parent_arguments
            inherited.merge(own_arguments)
          end

          # Get arguments from parent class if available
          #
          # @return [Hash] parent arguments or empty hash
          sig { returns(T::Hash[Symbol, Settings::Field]) }
          def parent_arguments
            # self is actually a Class when this module is extended, so we can call superclass
            parent = T.unsafe(self).superclass
            return {} unless parent.respond_to?(:arguments)

            # The parent class responds to arguments, so we can safely call it
            result = parent.send(:arguments)
            result.is_a?(Hash) ? result.dup : {}
          end
        end
      end
    end
  end
end

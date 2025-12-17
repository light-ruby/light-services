# typed: strict
# frozen_string_literal: true

require_relative "../constants"
require_relative "validation"
require "sorbet-runtime"

module Light
  module Services
    module Dsl
      # DSL for defining and managing service outputs
      module OutputsDsl
        extend T::Sig
        extend T::Helpers

        sig { params(base: T.untyped).void }
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          extend T::Sig
          extend T::Helpers

          # Define an output for the service
          #
          # @param name [Symbol] the output name
          # @param opts [Hash] options for configuring the output
          # @option opts [Class, Array<Class>] :type Type(s) to validate against
          #   (e.g., Hash, String, [String, Symbol])
          # @option opts [Boolean] :optional (false) Whether nil values are allowed
          # @option opts [Object, Proc] :default Default value or proc to evaluate in instance context
          #
          # @example Define a required hash output
          #   output :result, type: Hash
          #
          # @example Define an optional output with default
          #   output :status, type: String, optional: true, default: "pending"
          #
          # @example Define an output with multiple allowed types
          #   output :data, type: [Hash, Array]
          #
          # @example Define an output with proc default
          #   output :metadata, type: Hash, default: -> { {} }
          sig { params(name: T.untyped, opts: T::Hash[Symbol, T.untyped]).void }
          def output(name, opts = {})
            Validation.validate_symbol_name!(name, :output, self)
            Validation.validate_reserved_name!(name, :output, self)
            Validation.validate_name_conflicts!(name, :output, self)
            Validation.validate_type_required!(name, :output, self, opts)

            own_outputs[T.cast(name, Symbol)] = Settings::Field.new(name, self, opts.merge(field_type: FieldTypes::OUTPUT))
            @outputs = T.let(nil, T.nilable(T::Hash[Symbol, Settings::Field]))
          end

          # Remove an output from the service
          #
          # @param name [Symbol] the output name to remove
          sig { params(name: Symbol).void }
          def remove_output(name)
            own_outputs.delete(name)
            @outputs = T.let(nil, T.nilable(T::Hash[Symbol, Settings::Field]))
          end

          # Get all outputs including inherited ones
          #
          # @return [Hash] all outputs defined for this service
          sig { returns(T::Hash[Symbol, Settings::Field]) }
          def outputs
            @outputs = T.let(@outputs, T.nilable(T::Hash[Symbol, Settings::Field]))
            @outputs ||= build_outputs
          end

          # Get only outputs defined in this class
          #
          # @return [Hash] outputs defined in this class only
          sig { returns(T::Hash[Symbol, Settings::Field]) }
          def own_outputs
            @own_outputs = T.let(@own_outputs, T.nilable(T::Hash[Symbol, Settings::Field]))
            @own_outputs ||= {}
          end

          private

          # Build outputs by merging inherited outputs with own outputs
          #
          # @return [Hash] merged outputs
          sig { returns(T::Hash[Symbol, Settings::Field]) }
          def build_outputs
            inherited = parent_outputs
            inherited.merge(own_outputs)
          end

          # Get outputs from parent class if available
          #
          # @return [Hash] parent outputs or empty hash
          sig { returns(T::Hash[Symbol, Settings::Field]) }
          def parent_outputs
            # self is actually a Class when this module is extended, so we can call superclass
            parent = T.unsafe(self).superclass
            return {} unless parent.respond_to?(:outputs)

            # The parent class responds to outputs, so we can safely call it
            result = parent.send(:outputs)
            result.is_a?(Hash) ? result.dup : {}
          end
        end
      end
    end
  end
end

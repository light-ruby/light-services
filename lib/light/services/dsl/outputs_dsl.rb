# frozen_string_literal: true

module Light
  module Services
    module Dsl
      # DSL for defining and managing service outputs
      module OutputsDsl
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          # Define an output for the service
          #
          # @param name [Symbol] the output name
          # @param opts [Hash] options for the output (type, optional, default, etc.)
          def output(name, opts = {})
            own_outputs[name] = Settings::Field.new(name, self, opts.merge(field_type: :output))
            @outputs = nil # Clear memoized outputs since we're modifying them
          end

          # Remove an output from the service
          #
          # @param name [Symbol] the output name to remove
          def remove_output(name)
            own_outputs.delete(name)
            @outputs = nil # Clear memoized outputs since we're modifying them
          end

          # Get all outputs including inherited ones
          #
          # @return [Hash] all outputs defined for this service
          def outputs
            @outputs ||= build_outputs
          end

          # Get only outputs defined in this class
          #
          # @return [Hash] outputs defined in this class only
          def own_outputs
            @own_outputs ||= {}
          end

          private

          # Build outputs by merging inherited outputs with own outputs
          #
          # @return [Hash] merged outputs
          def build_outputs
            inherited = superclass.respond_to?(:outputs) ? superclass.outputs.dup : {}
            inherited.merge(own_outputs)
          end
        end
      end
    end
  end
end

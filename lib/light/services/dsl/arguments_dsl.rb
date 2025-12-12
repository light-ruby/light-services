# frozen_string_literal: true

module Light
  module Services
    module Dsl
      # DSL for defining and managing service arguments
      module ArgumentsDsl
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          # Define an argument for the service
          #
          # @param name [Symbol] the argument name
          # @param opts [Hash] options for the argument (type, optional, default, etc.)
          def arg(name, opts = {})
            own_arguments[name] = Settings::Field.new(name, self, opts.merge(field_type: :argument))
            @arguments = nil # Clear memoized arguments since we're modifying them
          end

          # Remove an argument from the service
          #
          # @param name [Symbol] the argument name to remove
          def remove_arg(name)
            own_arguments.delete(name)
            @arguments = nil # Clear memoized arguments since we're modifying them
          end

          # Get all arguments including inherited ones
          #
          # @return [Hash] all arguments defined for this service
          def arguments
            @arguments ||= build_arguments
          end

          # Get only arguments defined in this class
          #
          # @return [Hash] arguments defined in this class only
          def own_arguments
            @own_arguments ||= {}
          end

          private

          # Build arguments by merging inherited arguments with own arguments
          #
          # @return [Hash] merged arguments
          def build_arguments
            inherited = superclass.respond_to?(:arguments) ? superclass.arguments.dup : {}
            inherited.merge(own_arguments)
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Light
  module Services
    module Dsl
      # DSL for defining and managing service steps
      module StepsDsl
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          # Define a step for the service
          #
          # @param name [Symbol] the step name
          # @param opts [Hash] options for the step (if, unless, always, before, after, etc.)
          def step(name, opts = {})
            validate_step_opts!(name, opts)

            # Build current steps to check for duplicates and find insertion targets
            current = steps
            raise Light::Services::Error, "Step `#{name}` already exists in service #{self}" if current.key?(name)

            if (target = opts[:before] || opts[:after]) && !current.key?(target)
              raise Light::Services::Error, "Cannot find step `#{target}` in service #{self}"
            end

            step_obj = Settings::Step.new(name, self, opts)

            if opts[:before] || opts[:after]
              step_operations << { action: :insert, name: name, step: step_obj, before: opts[:before],
                                   after: opts[:after], }
            else
              step_operations << { action: :add, name: name, step: step_obj }
            end

            # Clear memoized steps since we're modifying them
            @steps = nil
          end

          # Remove a step from the service
          #
          # @param name [Symbol] the step name to remove
          def remove_step(name)
            step_operations << { action: :remove, name: name }

            # Clear memoized steps since we're modifying them
            @steps = nil
          end

          # Get all steps including inherited ones
          #
          # @return [Hash] all steps defined for this service
          def steps
            @steps ||= build_steps
          end

          # Get the list of step operations to be applied
          #
          # @return [Array] list of operations
          def step_operations
            @step_operations ||= []
          end

          private

          # Validate step options to ensure they are valid
          #
          # @param name [Symbol] the step name
          # @param opts [Hash] the step options
          def validate_step_opts!(name, opts)
            return unless opts[:before] && opts[:after]

            raise Light::Services::Error, "You cannot specify `before` and `after` " \
                                          "for step `#{name}` in service #{self} at the same time"
          end

          # Build steps by applying operations to inherited steps
          #
          # @return [Hash] the final steps hash
          def build_steps
            # Start with inherited steps
            result = inherit_steps

            # Apply operations in order
            step_operations.each { |op| apply_step_operation(result, op) }

            result
          end

          # Inherit steps from parent class
          #
          # @return [Hash] inherited steps
          def inherit_steps
            superclass.respond_to?(:steps) ? superclass.steps.dup : {}
          end

          # Apply a single step operation to the steps hash
          #
          # @param steps [Hash] the steps hash
          # @param operation [Hash] the operation to apply
          def apply_step_operation(steps, operation)
            case operation[:action]
            when :add
              steps[operation[:name]] = operation[:step]
            when :remove
              steps.delete(operation[:name])
            when :insert
              insert_step(steps, operation)
            end
          end

          # Insert a step before or after a target step
          #
          # @param steps [Hash] the steps hash
          # @param operation [Hash] the insert operation details
          def insert_step(steps, operation)
            target = operation[:before] || operation[:after]
            keys = steps.keys
            index = keys.index(target)
            return unless index

            # More efficient insertion using ordered hash reconstruction
            new_steps = {}

            keys.each_with_index do |key, i|
              # Insert before target
              new_steps[operation[:name]] = operation[:step] if operation[:before] && i == index
              new_steps[key] = steps[key]

              # Insert after target
              new_steps[operation[:name]] = operation[:step] if operation[:after] && i == index
            end

            steps.replace(new_steps)
          end
        end
      end
    end
  end
end

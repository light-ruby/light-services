# typed: strict
# frozen_string_literal: true

require_relative "../constants"
require_relative "validation"
require "sorbet-runtime"

module Light
  module Services
    module Dsl
      # DSL for defining and managing service steps
      module StepsDsl
        extend T::Sig

        sig { params(base: T.untyped).void }
        def self.included(base)
          base.extend(ClassMethods)
        end

        # rubocop:disable Metrics/ModuleLength
        module ClassMethods
          extend T::Sig

          # Define a step for the service
          #
          # @param name [Symbol] the step name (must correspond to a private method)
          # @param opts [Hash] options for configuring the step
          # @option opts [Symbol, Proc] :if Condition to determine if step should run
          # @option opts [Symbol, Proc] :unless Condition to skip step (returns truthy to skip)
          # @option opts [Boolean] :always (false) Run step even after errors/warnings
          # @option opts [Symbol] :before Insert this step before the specified step
          # @option opts [Symbol] :after Insert this step after the specified step
          #
          # @example Define a simple step
          #   step :validate_input
          #
          # @example Define a conditional step
          #   step :send_notification, if: :should_notify?
          #   step :skip_validation, unless: :production?
          #
          # @example Define a step that always runs
          #   step :cleanup, always: true
          #
          # @example Define step ordering
          #   step :log_start, before: :validate_input
          #   step :log_end, after: :process_data
          #
          # @example Define a step with proc condition
          #   step :premium_feature, if: -> { user.premium? && feature_enabled? }
          sig { params(name: T.untyped, opts: T::Hash[Symbol, T.untyped]).void }
          def step(name, opts = {}) # rubocop:disable Metrics/MethodLength
            Validation.validate_symbol_name!(name, :step, self)
            Validation.validate_reserved_name!(name, :step, self)
            Validation.validate_name_conflicts!(name, :step, self)
            validate_step_opts!(name, opts)

            name_sym = T.cast(name, Symbol)

            # Build current steps to check for duplicates and find insertion targets
            current = steps
            if current.key?(name_sym)
              Kernel.raise Light::Services::Error,
                           "Step `#{name}` is already defined in service #{self}. Each step must have a unique name."
            end

            if (target = opts[:before] || opts[:after]) && !current.key?(target)
              available = current.keys.join(", ")
              Kernel.raise Light::Services::Error,
                           "Cannot find target step `#{target}` in service #{self}. Available steps: [#{available}]"
            end

            step_obj = Settings::Step.new(name_sym, self, opts)

            operation = if opts[:before] || opts[:after]
                          Settings::InsertStepOperation.new(
                            name_sym,
                            step_obj,
                            before: opts[:before],
                            after: opts[:after],
                          )
                        else
                          Settings::AddStepOperation.new(name_sym, step_obj)
                        end

            step_operations << operation

            # Clear memoized steps since we're modifying them
            @steps = nil
          end

          # Remove a step from the service
          #
          # @param name [Symbol] the step name to remove
          sig { params(name: Symbol).void }
          def remove_step(name)
            step_operations << Settings::RemoveStepOperation.new(name)

            # Clear memoized steps since we're modifying them
            @steps = T.let(nil, T.nilable(T::Hash[Symbol, Settings::Step]))
          end

          # Get all steps including inherited ones
          #
          # @return [Hash] all steps defined for this service
          sig { returns(T::Hash[Symbol, Settings::Step]) }
          def steps
            @steps = T.let(@steps, T.nilable(T::Hash[Symbol, Settings::Step]))
            @steps ||= build_steps
          end

          # Get the list of step operations to be applied
          #
          # @return [Array] list of operations
          sig { returns(T::Array[Settings::StepOperation]) }
          def step_operations
            @step_operations = T.let(@step_operations, T.nilable(T::Array[Settings::StepOperation]))
            @step_operations ||= []
          end

          # Validate that the service has steps defined
          # Called before executing the service
          #
          # @raise [NoStepsError] if no steps are defined
          sig { void }
          def validate_steps!
            return unless steps.empty?

            Kernel.raise Light::Services::NoStepsError,
                         "Service #{self} has no steps defined. Define at least one step or implement a `run` method."
          end

          private

          # Validate step options to ensure they are valid
          #
          # @param name [Symbol] the step name
          # @param opts [Hash] the step options
          sig { params(name: Symbol, opts: T::Hash[Symbol, T.untyped]).void }
          def validate_step_opts!(name, opts)
            return unless opts[:before] && opts[:after]

            Kernel.raise Light::Services::Error, "You cannot specify `before` and `after` " \
                                                 "for step `#{name}` in service #{self} at the same time"
          end

          # Build steps by applying operations to inherited steps
          #
          # @return [Hash] the final steps hash
          sig { returns(T::Hash[Symbol, Settings::Step]) }
          def build_steps
            # Start with inherited steps
            result = inherit_steps

            # Apply operations in order
            step_operations.each { |op| apply_step_operation(result, op) }

            # If no steps defined, check for `run` method as fallback
            result[:run] = Settings::Step.new(:run, self, {}) if result.empty? && instance_method_defined?(:run)

            result
          end

          # Check if an instance method is defined in this class or its ancestors
          # (excluding Light::Services::Base and its modules)
          #
          # @param method_name [Symbol] the method name to check
          # @return [Boolean] true if the method is defined
          sig { params(method_name: Symbol).returns(T::Boolean) }
          def instance_method_defined?(method_name)
            # self is actually a Class when this module is extended
            klass = T.unsafe(self)

            # Check if method exists and is not from base service classes
            return false unless klass.method_defined?(method_name) || klass.private_method_defined?(method_name)

            # Get the method owner to ensure it's defined in user's service class
            owner = klass.instance_method(method_name).owner

            # Method should be defined in a class that inherits from Base,
            # not in Base itself or its included modules
            !owner.to_s.start_with?("Light::Services")
          end

          # Inherit steps from parent class
          #
          # @return [Hash] inherited steps
          sig { returns(T::Hash[Symbol, Settings::Step]) }
          def inherit_steps
            # self is actually a Class when this module is extended
            parent = T.unsafe(self).superclass
            parent.respond_to?(:steps) ? parent.steps.dup : {}
          end

          # Apply a single step operation to the steps hash
          #
          # @param steps [Hash] the steps hash
          # @param operation [StepOperation] the operation to apply
          sig { params(steps: T::Hash[Symbol, Settings::Step], operation: Settings::StepOperation).void }
          def apply_step_operation(steps, operation)
            case operation
            when Settings::AddStepOperation
              steps[operation.name] = operation.step
            when Settings::RemoveStepOperation
              steps.delete(operation.name)
            when Settings::InsertStepOperation
              insert_step(steps, operation)
            else
              T.absurd(operation)
            end
          end

          # Insert a step before or after a target step
          #
          # @param steps [Hash] the steps hash
          # @param operation [InsertStepOperation] the insert operation details
          sig { params(steps: T::Hash[Symbol, Settings::Step], operation: Settings::InsertStepOperation).void }
          def insert_step(steps, operation)
            target = operation.target
            keys = steps.keys
            index = keys.index(target)
            return unless index

            # More efficient insertion using ordered hash reconstruction
            new_steps = T.let({}, T::Hash[Symbol, Settings::Step])

            keys.each_with_index do |key, i|
              # Insert before target
              new_steps[operation.name] = operation.step if operation.before && i == index
              new_steps[key] = T.must(steps[key])

              # Insert after target
              new_steps[operation.name] = operation.step if operation.after && i == index
            end

            steps.replace(new_steps)
          end
        end
        # rubocop:enable Metrics/ModuleLength
      end
    end
  end
end

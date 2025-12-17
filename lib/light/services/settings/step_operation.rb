# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

module Light
  module Services
    module Settings
      # Type alias for step operation types
      StepOperationType = T.type_alias { T.any(AddStepOperation, RemoveStepOperation, InsertStepOperation) }

      # Base class for step operations using sealed inheritance.
      # Each operation type has specific fields for its action.
      class StepOperation
        extend T::Sig
        extend T::Helpers

        abstract!
        sealed!

        sig { returns(Symbol) }
        attr_reader :name

        sig { params(name: Symbol).void }
        def initialize(name)
          @name = T.let(name, Symbol)
        end
      end

      # Operation to add a new step to the service
      class AddStepOperation < StepOperation
        sig { returns(Step) }
        attr_reader :step

        sig { params(name: Symbol, step: Step).void }
        def initialize(name, step)
          super(name)
          @step = T.let(step, Step)
        end
      end

      # Operation to remove a step from the service
      class RemoveStepOperation < StepOperation
        # Inherits name from parent, no additional fields needed
      end

      # Operation to insert a step before or after another step
      class InsertStepOperation < StepOperation
        sig { returns(Step) }
        attr_reader :step

        sig { returns(T.nilable(Symbol)) }
        attr_reader :before

        sig { returns(T.nilable(Symbol)) }
        attr_reader :after

        sig { params(name: Symbol, step: Step, before: T.nilable(Symbol), after: T.nilable(Symbol)).void }
        def initialize(name, step, before: nil, after: nil)
          super(name)
          @step = T.let(step, Step)
          @before = T.let(before, T.nilable(Symbol))
          @after = T.let(after, T.nilable(Symbol))
        end

        # Get the target step (before or after)
        sig { returns(Symbol) }
        def target
          T.must(@before || @after)
        end
      end
    end
  end
end

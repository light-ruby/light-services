# frozen_string_literal: true

class WithStepInsertion < ApplicationService
  # Outputs
  output :execution_order, default: []

  # Steps
  step :step_a
  step :step_c
  step :step_b, before: :step_c

  private

  def step_a
    execution_order << :a
  end

  def step_b
    execution_order << :b
  end

  def step_c
    execution_order << :c
  end
end

class WithStepRemoval < ApplicationService
  # Outputs
  output :execution_order, default: []

  # Steps
  step :step_a
  step :step_b
  step :step_c

  remove_step :step_b

  private

  def step_a
    execution_order << :a
  end

  def step_b
    execution_order << :b
  end

  def step_c
    execution_order << :c
  end
end

class WithStepAfter < ApplicationService
  # Outputs
  output :execution_order, default: []

  # Steps
  step :step_a
  step :step_c
  step :step_b, after: :step_a

  private

  def step_a
    execution_order << :a
  end

  def step_b
    execution_order << :b
  end

  def step_c
    execution_order << :c
  end
end

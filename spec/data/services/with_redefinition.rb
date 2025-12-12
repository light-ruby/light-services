# frozen_string_literal: true

# Base service with arguments and outputs that will be redefined
class WithRedefinitionBase < ApplicationService
  # Arguments that will be redefined in child classes
  arg :name, type: String
  arg :count, type: Integer, default: 10
  arg :options, type: Hash, optional: true

  # Outputs that will be redefined in child classes
  output :result, type: String
  output :data, type: Hash, default: {}
  output :status, type: String, optional: true

  step :process

  private

  def process
    self.result = "Base: #{name}"
    self.data = { count: count }
  end
end

# Child service that redefines argument types
class WithRedefinedArgTypes < WithRedefinitionBase
  # Redefine :name to accept multiple types
  arg :name, type: [String, Symbol]

  # Redefine :count to be optional with different default
  arg :count, type: Integer, optional: true, default: 5

  # Redefine :options to be required (not optional)
  arg :options, type: Hash

  private

  def process
    self.result = "Child: #{name}"
    self.data = { count: count, options: options }
  end
end

# Child service that redefines output types
class WithRedefinedOutputTypes < WithRedefinitionBase
  # Redefine :result to accept multiple types
  output :result, type: [String, Symbol]

  # Redefine :data to be optional
  output :data, type: Hash, optional: true

  # Redefine :status to be required with a type
  output :status, type: Symbol

  private

  def process
    self.result = :child_result
    self.data = nil
    self.status = :success
  end
end

# Child service that redefines defaults only
class WithRedefinedDefaults < WithRedefinitionBase
  # Same types but different defaults
  arg :count, type: Integer, default: 100
  output :data, type: Hash, default: { initialized: true }

  private

  def process
    self.result = "Defaults: #{name}"
    # Don't set data to test default
  end
end

# Grandchild service to test multi-level inheritance
class WithRedefinedGrandchild < WithRedefinedArgTypes
  # Redefine again in grandchild
  arg :name, type: String  # Back to String only
  arg :extra, type: String, optional: true  # Add new argument

  output :extra_output, type: String, optional: true  # Add new output

  private

  def process
    self.result = "Grandchild: #{name}"
    self.data = { count: count, options: options, extra: extra }
    self.extra_output = extra if extra?
  end
end

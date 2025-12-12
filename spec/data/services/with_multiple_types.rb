# frozen_string_literal: true

class WithMultipleTypes < ApplicationService
  # Arguments with multiple types
  arg :value, type: [String, Integer]
  arg :flag, type: [TrueClass, FalseClass], optional: true
  arg :data, type: Hash, optional: true

  # Steps
  step :process

  private

  def process
    # Just validate types
  end
end

# frozen_string_literal: true

class WithException < ApplicationService
  # Steps
  step :raise_exception
  step :never_reached
  step :always_run, always: true

  # Outputs
  output :always_step_ran, default: false

  private

  def raise_exception
    raise StandardError, "Something went wrong!"
  end

  def never_reached
    # This should never be called
  end

  def always_run
    self.always_step_ran = true
  end
end

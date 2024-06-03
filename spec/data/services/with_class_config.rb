# frozen_string_literal: true

class WithClassConfig < ApplicationService
  # Config
  config raise_on_error: true

  # Steps
  step :add_error

  private

  def add_error
    errors.add(:base, "This is an error")
  end
end

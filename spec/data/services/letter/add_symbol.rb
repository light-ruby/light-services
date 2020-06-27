# frozen_string_literal: true

class Letter::AddSymbol < ApplicationService
  # Constants
  VALIDATION_EXPRESSION = /[^\w]/

  # Arguments
  arg :word, type: String
  arg :symbol, type: String

  # Outputs
  output :word_with_symbol

  # Steps
  step :validate_symbol
  step :add_symbol

  private

  def validate_symbol
    return if symbol =~ VALIDATION_EXPRESSION

    errors.add(:symbol, "symbol must be a symbol")
  end

  def add_symbol
    self.word_with_symbol = word + symbol
  end
end

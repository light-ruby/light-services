# frozen_string_literal: true

class Letter::BuildWord < ApplicationService
  # Arguments
  arg :letters, type: Array
  arg :symbol,  type: String, context: true, optional: true
  arg :reverse, type: :boolean, default: false

  # Outputs
  output :word, default: ""

  # Steps
  step :validate_letters
  step :add_letters
  step :add_symbol, if: :symbol?
  step :reverse_word, if: :reverse?

  private

  def validate_letters
    letters.each do |letter|
      next if letter.is_a?(String)

      errors.add(:letters, "wrong type of letter: #{letter}")
    end
  end

  def add_letters
    letters.each do |letter|
      self.word += letter
    end
  end

  def add_symbol
    self.word = Letter::AddSymbol
      .with(self)
      .run(word: word)
      .word_with_symbol
  end
end

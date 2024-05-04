# frozen_string_literal: true

class Product < ApplicationRecord
  # Validations
  validates :name, uniqueness: true, presence: true
  validates :price, numericality: { greater_than_or_equal: 0 }, presence: true
end

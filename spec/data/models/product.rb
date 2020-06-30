# frozen_string_literal: true

class Product < ApplicationRecord
  # Validations
  validates :name, uniqueness: true, presence: true
end

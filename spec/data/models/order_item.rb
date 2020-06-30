# frozen_string_literal: true

class OrderItem < ApplicationRecord
  # Associations
  belongs_to :order
  belongs_to :product

  # Validations
  validates :price, numericality: { greater_than_or_equal: 0 }
end

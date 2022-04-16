# frozen_string_literal: true

class Order < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items

  # Validations
  validates :total_price, numericality: { greater_than_or_equal: 0 }
  validates :discount, numericality: { greater_than_or_equal: 0 }

  # Enumerables
  enum status: {
    in_progress: 1,
    completed: 2,
    canceled: 3
  }
end

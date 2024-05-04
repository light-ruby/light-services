# frozen_string_literal: true

class User < ApplicationRecord
  # Associations
  has_many :orders, dependent: :destroy

  # Validations
  validates :name, uniqueness: true, presence: true
end

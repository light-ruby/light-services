# frozen_string_literal: true

require "dry-types"

module Types
  include Dry.Types()
end

class WithDryTypes < ApplicationService
  # Arguments with dry-types validation
  arg :name, type: Types::Strict::String
  arg :age, type: Types::Coercible::Integer
  arg :email, type: Types::String.constrained(format: /\A[\w+\-.]+@[a-z\d-]+(\.[a-z]+)*\.[a-z]+\z/i), optional: true
  arg :status, type: Types::String.enum("active", "inactive", "pending"), default: "pending"
  arg :tags, type: Types::Array.of(Types::String), optional: true
  arg :metadata, type: Types::Hash.schema(key: Types::String).with_key_transform(&:to_sym), optional: true

  # Outputs with dry-types validation
  output :greeting, type: Types::Strict::String
  output :user_age, type: Types::Strict::Integer
  output :full_data, type: Types::Hash, optional: true

  # Steps
  step :build_greeting
  step :set_age
  step :build_data

  private

  def build_greeting
    self.greeting = "Hello, #{name}!"
  end

  def set_age
    self.user_age = age
  end

  def build_data
    self.full_data = {
      name: name,
      age: user_age,
      status: status,
      tags: tags || [],
      email: email,
    }
  end
end

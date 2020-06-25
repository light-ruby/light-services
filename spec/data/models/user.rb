# frozen_string_literal: true

class User
  def initialize(name = nil)
    @name = name
  end

  def assign_attributes(attributes = {})
    @name = attributes[:name]
  end

  def save!; end
end

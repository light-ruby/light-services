# frozen_string_literal: true

class Order::Create < CreateService
  # Steps
  step :assign_user, after: :initialize_entity
  step :assign_default_attributes, before: :assign_attributes
  remove_step :assign_attributes

  def order
    entity
  end

  private

  def assign_user
    order.user = current_user
  end

  def assign_default_attributes
    order.status = :in_progress
    order.total_price = 0
    order.discount = 0
  end

  def entity_class
    Order
  end
end

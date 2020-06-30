# frozen_string_literal: true

class Order::AddProduct < ApplicationService
  # Arguments
  arg :order, type: Order, context: true
  arg :product, type: Product
  arg :quantity, type: Integer

  # Steps
  step :check_user
  step :check_order_status
  step :check_duplicates
  step :add_product
  step :recalculate_order

  private

  def check_user
    return if order.user == current_user

    errors.add(:base, "you are not authorized to access this order")
  end

  def check_order_status
    return if order.in_progress?

    errors.add(:status, "must be in progress")
  end

  def check_duplicates
    return if order.order_items.where(product: product).none?

    errors.add(:product, "already exists")
  end

  def add_product
    order_item = order.order_items.new(product: product, quantity: quantity, price: product.price)
    order_item.save!
  rescue ActiveRecord::RecordInvalid
    errors.from(order_item)
  end

  def recalculate_order
    Order::Recalculate.with(self).run
  end
end

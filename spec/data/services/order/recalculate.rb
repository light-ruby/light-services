# frozen_string_literal: true

class Order::Recalculate < ApplicationService
  # Arguments
  arg :order, type: Order

  # Steps
  step :check_order_status
  step :recalculate
  step :save

  private

  def check_order_status
    return if order.in_progress?

    errors.add(:status, "must be in progress")
  end

  def recalculate
    order.total_price = order.order_items.sum { |order_item| order_item.price * order_item.quantity }
    order.total_price -= order.total_price / 100 * order.discount
  end

  def save
    order.save!
  rescue ActiveRecord::RecordInvalid
    errors.from(order)
  end
end

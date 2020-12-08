# frozen_string_literal: true

class Product::AddToCart < ApplicationService
  # Arguments
  arg :product, type: Product
  arg :current_user, type: User
  arg :quantity, type: Integer, default: 1

  # Outputs
  output :order

  # Steps
  step :find_existed_order
  step :create_new_order, unless: :order?
  step :add_product_to_order

  private

  def find_existed_order
    self.order = current_user.orders.in_progress.take
  end

  def create_new_order
    self.order = Order::Create
      .with(self)
      .run
      .order
  end

  def add_product_to_order
    Order::AddProduct
      .with(self)
      .run(order: order, product: product, quantity: quantity)
  end
end

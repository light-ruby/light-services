# frozen_string_literal: true

class Order::Update < UpdateService
  # Arguments
  arg :order, type: Order

  private

  def argument_key
    :order
  end

  def authorize
    return if order == current_order

    errors.add(:order, "you are not authorized to update this order")
  end

  # If you're using Rails just use:
  #
  #   params.require(:order).permit(:name)
  #
  def filtered_params
    errors.add(:params, "key `order` must be a Hash") unless params[:order].is_a?(Hash)

    params[:order].slice(:name)
  end
end

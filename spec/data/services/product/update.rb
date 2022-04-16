# frozen_string_literal: true

class Product::Update < UpdateService
  # Arguments
  arg :product, type: Product

  private

  def argument_key
    :product
  end

  def authorize
    return if product == current_product

    errors.add(:product, "you are not authorized to update this product")
  end

  # If you're using Rails just use:
  #
  #   params.require(:product).permit(:name)
  #
  def filtered_params
    errors.add(:params, "key `product` must be a Hash") unless params[:product].is_a?(Hash)

    params[:product].slice(:name)
  end
end

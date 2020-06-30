# frozen_string_literal: true

class Product::Create < CreateService
  def product
    entity
  end

  private

  def entity_class
    Product
  end

  # If you're using Rails just use:
  #
  #   params.require(:product).permit(:user_id)
  #
  def filtered_params
    errors.add(:params, "key `product` must be a Hash") unless params[:product].is_a?(Hash)

    params[:product].slice(:user_id)
  end
end

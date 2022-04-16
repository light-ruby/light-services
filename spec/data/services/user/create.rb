# frozen_string_literal: true

class User::Create < CreateService
  def user
    entity
  end

  private

  def entity_class
    User
  end

  # If you're using Rails just use:
  #
  #   params.require(:user).permit(:name)
  #
  def filtered_params
    errors.add(:params, "key `user` must be a Hash") unless params[:user].is_a?(Hash)

    params[:user].slice(:name)
  end
end

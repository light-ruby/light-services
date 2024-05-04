# frozen_string_literal: true

class User::Update < UpdateService
  # Arguments
  arg :user, type: User

  private

  def argument_key
    :user
  end

  def authorize
    return if user == current_user

    errors.add(:user, "you are not authorized to update this user")
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

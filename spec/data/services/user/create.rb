# frozen_string_literal: true

class User::Create < CreateService
  # Steps
  step :hello_world, after: :initialize_entity
  step :wat, before: :authorize
  remove_step :log_action

  def entity_class
    User
  end

  def filtered_params
    # If you're using Rails:
    # params.require(:user).permit(:name)

    params[:user]&.slice(:user) || {}
  end

  def hello_world

  end

  def wat

  end
end

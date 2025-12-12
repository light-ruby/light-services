# frozen_string_literal: true

class WithTypedOutputs < ApplicationService
  # Arguments
  arg :user_name, type: String, optional: true
  arg :return_wrong_type, type: :boolean, default: false

  # Steps
  step :create_user, if: :user_name?
  step :build_message
  step :set_wrong_type, if: :return_wrong_type?

  # Outputs with type validation
  output :user, type: User, optional: true
  output :message, type: String
  output :count, type: Integer, default: 0
  output :data, type: :hash, optional: true

  private

  def create_user
    self.user = User.create!(name: user_name)
  end

  def build_message
    self.message = user? ? "Hello, #{user.name}!" : "Hello, World!"
    self.count = message.length
  end

  def set_wrong_type
    # Intentionally set wrong type to test validation
    self.message = 123
  end
end

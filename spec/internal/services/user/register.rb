# frozen_string_literal: true

class User::Register < Light::Services::Base
  # Parameters
  param :first_name, type: String
  param :last_name,  type: String
  param :email,      type: String
  param :referer,    type: String, allow_nil: true

  # Outputs
  output :user, {}

  # Callbacks
  before :clear_data
  before :unique_email

  def run
    self.user = User.new(
      "#{first_name} #{parameters[:last_name]}",
      parameters[:email],
      false
    )
  end

  private

  def clear_data
    self.first_name = first_name.strip
    self.last_name  = last_name.strip
    self.email      = email.strip
    self.referer    = referer&.strip
  end

  def unique_email
    return unless %w[emelianenko.web@gmail.com].include?(email)
    errors.add(:email, :taken)
  end
end

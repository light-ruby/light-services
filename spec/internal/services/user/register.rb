class User::Register < Light::Service::Base
  # Parameters
  param :first_name, type: String
  param :last_name,  type: String
  param :email,      type: String

  # Outputs
  output :user, {}

  # Callbacks
  before :clear_data
  before :unique_email

  def run
    self.user = User.new(
      "#{first_name} #{params[:last_name]}",
      params[:email],
      false
    )
  end

  private

  def clear_data
    first_name.strip!
    last_name.strip!
    email.strip!
  end

  def unique_email
    return unless %w(emelianenko.web@gmail.com).include?(email)
    errors.add(:email, :taken)
  end
end

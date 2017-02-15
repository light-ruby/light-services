class User::Update < Light::Services::Base
  # Parameters
  param :user,         type: User
  param :attributes,   type: Hash
  param :current_user, type: User

  # Outputs
  output :updated, false
  output :finally_triggered, false

  # Callbacks
  before  :check_permissions
  before  :validate
  after   :after_update
  finally :finally

  def run
    user.update(attributes)
  end

  private

  def check_permissions
    return if user == current_user
    return if current_user.admin

    errors.add(:base, "You don't have permissions to update this user")
  end

  def validate
    errors.add(:attributes, :blank) if attributes.empty?
  end

  def after_update
    self.updated = true
  end

  def finally
    self.finally_triggered = true
  end
end

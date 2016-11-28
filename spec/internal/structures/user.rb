class User
  # Getters
  attr_accessor :full_name, :email, :admin

  def initialize(full_name, email, admin)
    @full_name = full_name
    @email = email
    @admin = admin
  end

  def update(attributes)
    self.full_name = attributes[:full_name] if attributes.key?(:full_name)
    self.email     = attributes[:email]     if attributes.key?(:email)
    self.admin     = attributes[:admin]     if attributes.key?(:admin)
  end
end

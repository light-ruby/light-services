# 🚀 Light Services

Light Services is a simple yet powerful way to organize your business logic. This Ruby gem helps you build services that are easy to test, maintain, and understand.

![GitHub CI](https://github.com/light-ruby/light-services/actions/workflows/ci.yml/badge.svg)
[![Codecov](https://codecov.io/gh/light-ruby/light-services/graph/badge.svg?token=IGJNZ2BQ26)](https://codecov.io/gh/light-ruby/light-services)

## Features

- 🧩 **Simple**: Define your service as a class with `arguments`, `steps`, and `outputs`
- 🎢 **Transactions**: Automatically rollback database changes if any step fails
- 👵 **Inheritance**: Inherit from other services to reuse logic seamlessly
- 🚨 **Error Handling**: Collect errors from steps and handle them your way
- ⛓️ **Context**: Run multiple services sequentially within the same context
- 🤔 **Framework Agnostic**: Compatible with Rails, Hanami, or any Ruby framework
- 🏗️ **Modularity**: Isolate and test your services with ease
- 🐛 **100% Test Coverage**: Bugs are not welcome here!
- 🛡️ **Battle-Tested**: In production use since 2017

## Quick Example

```ruby
class User::ResetPassword < Light::Services::Base
  # Arguments
  arg :user, type: User, optional: true
  arg :email, type: :string, optional: true
  arg :send_email, type: :boolean, default: true

  # Steps
  step :validate
  step :find_user, unless: :user?
  step :generate_reset_token
  step :save_reset_token
  step :send_reset_email, if: :send_email?

  # Outputs
  output :user, type: User
  output :reset_token, type: :string

  private

  def validate
    errors.add(:base, "user or email is required") if !user? && !email?
  end

  def find_user
    self.user = User.find_by("LOWER(email) = ?", email.downcase)
    errors.add(:email, "not found") unless user
  end

  def generate_reset_token
    self.reset_token = SecureRandom.hex(32)
  end

  def save_reset_token
    user.update!(
      reset_password_token: reset_token,
      reset_password_sent_at: Time.current,
    )
  rescue ActiveRecord::RecordInvalid => e
    errors.from_record(e.record)
  end

  def send_reset_email
    Mailer::SendEmail
      .with(self)
      .run(template: :reset_password, user:, reset_token:)
  end
end
```

## Documentation

You can find the full documentation at [light-services-docs.vercel.app](https://light-services-docs.vercel.app/).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

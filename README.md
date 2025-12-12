# 🚀 Light Services

Light Services is a simple yet powerful way to organize business logic in Ruby applications. Build services that are easy to test, maintain, and understand.

![GitHub CI](https://github.com/light-ruby/light-services/actions/workflows/ci.yml/badge.svg)
[![Codecov](https://codecov.io/gh/light-ruby/light-services/graph/badge.svg?token=IGJNZ2BQ26)](https://codecov.io/gh/light-ruby/light-services)

[Get started with Quickstart](https://light-services.kodkod.me/quickstart)

## Features

- ✨ **Simple**: Define your service as a class with `arguments`, `steps`, and `outputs`
- 📦 **No runtime dependencies**: Works stand-alone without requiring external gems at runtime
- 🔄 **Transactions**: Automatically rollback database changes if any step fails
- 🧬 **Inheritance**: Inherit from other services to reuse logic seamlessly
- ⚠️ **Error Handling**: Collect errors from steps and handle them your way
- 🔗 **Context**: Run multiple services sequentially within the same context
- 🧪 **RSpec Matchers**: Built-in RSpec matchers for expressive service tests
- 🌐 **Framework Agnostic**: Compatible with Rails, Hanami, or any Ruby framework
- 🧩 **Modularity**: Isolate and test your services with ease
- ✅ **100% Test Coverage**: Thoroughly tested and reliable
- ⚔️ **Battle-Tested**: In production use since 2017

## Simple Example

```ruby
class GreetService < Light::Services::Base
  # Arguments
  arg :name
  arg :age

  # Steps
  step :build_message
  step :send_message

  # Outputs
  output :message

  private

  def build_message
    self.message = "Hello, #{name}! You are #{age} years old."
  end

  def send_message
    # Send logic goes here
  end
end
```

## Advanced Example

```ruby
class User::ResetPassword < Light::Services::Base
  # Arguments
  arg :user, type: User, optional: true
  arg :email, type: String, optional: true
  arg :send_email, type: [TrueClass, FalseClass], default: true

  # Steps
  step :validate
  step :find_user, unless: :user?
  step :generate_reset_token
  step :save_reset_token
  step :send_reset_email, if: :send_email?

  # Outputs
  output :user, type: User
  output :reset_token, type: String

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
      .with(self) # Call sub-service with the same context
      .run(template: :reset_password, user:, reset_token:)
  end
end
```

[Get started with Light Services](https://light-services.kodkod.me/quickstart)

## Documentation

You can find the full documentation at [light-services.kodkod.me](https://light-services.kodkod.me).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

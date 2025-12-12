# Context

Light Services can be run within the same context.

## What Does This Mean?

- Services will share arguments marked as `context: true`.
- If any service fails, the entire context will fail and rollback database changes.

## How to Run Services in the Same Context

To run a service in the same context, call `with(self)` before the `#run` method.

## Context Rollback

### Example:

Let's say we have two services: `User::Create` and `Profile::Create`. We want to ensure that if either service fails, all database changes are rolled back.

```ruby
class User::Create < ApplicationService
  # Arguments
  arg :attributes, type: :hash

  # Steps
  step :create_user
  step :create_profile
  step :send_welcome_email

  # Outputs
  output :user, type: User
  output :profile, type: Profile

  def create_user
    self.user = User.create!(attributes)
  end

  def create_profile
    service = Profile::Create
      .with(self) # This runs the service in the same context
      .run(user:)

    self.profile = service.profile
  end

  # If the Profile::Create service fails, this step and any following steps won't execute
  # And all database changes will be rolled back
  def send_welcome_email
    # We don't run this service in the same context
    # Because we don't care too much if it fails
    service = Mailer::SendWelcomeEmail.run(user:)

    # Handle the failure manually if needed
    if service.failed?
      # Handle the failure
    end
  end
end
```

## Context Arguments

Context arguments are shared between services running in the same context. This can make them a bit less predictable and harder to test.

It's recommended to use context arguments only when necessary and keep them as close to the root service as possible. For example, you can use them to share `current_user` or `current_organization` between services.

```ruby
class ApplicationService < Light::Services::Base
  arg :current_user, type: User, context: true
end
```

```ruby
class Comment::Create < ApplicationService
  # Arguments
  # We don't need to specify current_user here
  # as it's automatically inherited from the ApplicationService
  arg :post_id, type: :integer
  arg :text, type: :string
  arg :subscribe, type: :boolean

  # Steps
  step :create_comment
  step :subscribe_to_post, if: :subscribe?

  private

  def create_comment
    # ...
  end

  def subscribe_to_post
    Post::Subscribe
      .with(self) # Run service in the same context
      .run(post_id:) # We omit current_user here as context will handle it for us

    # If we run Post::Subscribe without `with(self)`
    # It'll fail because it won't have information about the `current_user`
  end
end
```

```ruby
class Post::Subscribe < ApplicationService
  # Arguments
  arg :post_id, type: :integer

  # Steps
  step :subscribe

  private

  def subscribe
    # We have access to current_user here because we run it in the same context
    #
    # Even if we would run this service without context this won't be a problem
    # because we specified this argument in top-level service (ApplicationService)
    current_user.subscriptions.create!(post_id:)
  end
end
```

# What's Next?

The next step is to learn about error handling in Light Service.

[Next: Errors](errors.md)


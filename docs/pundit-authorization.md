# Pundit Authorization

[Pundit](https://github.com/varvet/pundit) is a simple, flexible authorization library for Ruby on Rails. This recipe shows how to integrate Pundit authorization into your Light Services.

## Why Use Pundit with Services?

- **Centralized authorization**: Keep authorization logic in policy classes
- **Consistent patterns**: Same authorization approach across controllers and services
- **Testable**: Policies are easy to unit test
- **Reusable**: Services can be called from controllers, jobs, or other services with consistent authorization

## Basic Setup

### 1. Create an Authorization Concern

```ruby
# app/services/concerns/authorize_user.rb
module AuthorizeUser
  extend ActiveSupport::Concern

  included do
    arg :current_user, type: User, optional: true, context: true
  end

  # Authorize an action on a record or class
  def auth(record, action)
    policy = policy(record)
    
    unless policy.public_send(action)
      errors.add(:authorization, "You are not authorized to perform this action")
    end
  end
  alias_method :authorize!, :auth

  # Get permitted attributes for an action
  def permitted_attributes(record, action = nil)
    policy = policy(record)
    
    method_name = if action
      "permitted_attributes_for_#{action}"
    else
      "permitted_attributes"
    end

    if policy.respond_to?(method_name)
      attributes = policy.public_send(method_name)
      params.require(param_key(record)).permit(*attributes)
    else
      raise Pundit::NotDefinedError, "#{method_name} not defined in #{policy.class}"
    end
  end

  private

  def policy(record)
    Pundit.policy!(current_user, record)
  end

  def param_key(record)
    if record.is_a?(Class)
      record.model_name.param_key
    else
      record.model_name.param_key
    end
  end
end
```

### 2. Include in ApplicationService

```ruby
# app/services/application_service.rb
class ApplicationService < Light::Services::Base
  include AuthorizeUser
end
```

## Usage Examples

### Authorizing Actions

```ruby
class Post::Update < ApplicationService
  arg :post, type: Post
  arg :attributes, type: Hash

  step :authorize
  step :update_post

  private

  def authorize
    auth(post, :update?)
  end

  def update_post
    post.update!(attributes)
  end
end
```

### Authorizing on a Class (for Create actions)

```ruby
class Post::Create < ApplicationService
  arg :attributes, type: Hash

  step :authorize
  step :create_post

  output :post

  private

  def authorize
    auth(Post, :create?)
  end

  def create_post
    self.post = Post.create!(attributes)
  end
end
```

### Using Permitted Attributes

```ruby
class Post::Create < ApplicationService
  step :authorize
  step :create_post

  output :post

  private

  def authorize
    auth(Post, :create?)
  end

  def create_post
    self.post = Post.create!(permitted_attributes(Post, :create))
  end
end
```

## Policy Example

```ruby
# app/policies/post_policy.rb
class PostPolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def update?
    user.present? && (record.author == user || user.admin?)
  end

  def destroy?
    user.present? && (record.author == user || user.admin?)
  end

  def permitted_attributes_for_create
    [:title, :body, :category_id]
  end

  def permitted_attributes_for_update
    attributes = [:title, :body]
    attributes << :category_id if user.admin?
    attributes
  end
end
```

## Integration with CRUD Services

Combine Pundit with the [CRUD recipe](crud.md) for powerful, authorized services:

```ruby
# app/services/create_record_service.rb
class CreateRecordService < ApplicationService
  arg :record_class, type: Class
  arg :attributes, type: Hash, default: {}

  step :authorize
  step :create_record

  output :record

  private

  def authorize
    auth(record_class, :create?)
  end

  def create_record
    attrs = permitted_attributes(record_class, :create)
              .to_h
              .merge(attributes)
    
    self.record = record_class.create!(attrs)
  rescue ActiveRecord::RecordInvalid => e
    errors.copy_from(e.record)
  end
end
```

## Handling Authorization Failures

### Option 1: Collect as Errors (Default)

```ruby
def authorize
  auth(record, :update?)
  # If unauthorized, an error is added and subsequent steps are skipped
end
```

### Option 2: Raise Exceptions

```ruby
def authorize
  unless policy(record).update?
    raise Pundit::NotAuthorizedError, "not authorized to update this record"
  end
end
```

### Option 3: Custom Error Handling

```ruby
def authorize
  return if policy(record).update?
  
  errors.add(:base, I18n.t("pundit.not_authorized"))
end
```

## Testing Services with Authorization

```ruby
RSpec.describe Post::Update do
  let(:author) { create(:user) }
  let(:other_user) { create(:user) }
  let(:post) { create(:post, author: author) }

  context "when user is the author" do
    it "updates the post" do
      service = described_class.run(
        current_user: author,
        post: post,
        attributes: { title: "New Title" }
      )

      expect(service).to be_success
      expect(post.reload.title).to eq("New Title")
    end
  end

  context "when user is not the author" do
    it "returns authorization error" do
      service = described_class.run(
        current_user: other_user,
        post: post,
        attributes: { title: "New Title" }
      )

      expect(service).to be_failed
      expect(service.errors[:authorization]).to be_present
    end
  end

  context "when no user is provided" do
    it "returns authorization error" do
      service = described_class.run(
        current_user: nil,
        post: post,
        attributes: { title: "New Title" }
      )

      expect(service).to be_failed
    end
  end
end
```

## Skipping Authorization

For system-level operations or background jobs where authorization isn't needed:

```ruby
class Post::SystemUpdate < UpdateRecordService
  # Remove the authorize step for system operations
  remove_step :authorize
end
```

Or create a "system" flag:

```ruby
class ApplicationService < Light::Services::Base
  arg :system, type: :boolean, default: false, context: true
end

class Post::Update < ApplicationService
  step :authorize, unless: :system?
  step :update_post
  
  # ...
end

# Usage in background job
Post::Update.run(post: post, attributes: attrs, system: true)
```

## What's Next?

Return to the recipes overview:

[Back to Recipes](recipes.md)

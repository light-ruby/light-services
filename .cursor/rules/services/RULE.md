---
description: "Rules for managing Light Services - Ruby service objects with arguments, steps, and outputs"
globs: "**/services/**/*.rb"
alwaysApply: false
---

# Light Services Creation Rules

When creating or modifying services that inherit from `Light::Services::Base` or `ApplicationService`, follow these patterns.

## Service Structure

Always structure services in this order:
1. Configuration (`config`) if needed
2. Arguments (`arg`)
3. Steps (`step`)
4. Outputs (`output`)
5. Private methods implementing steps

```ruby
class ModelName::ActionName < ApplicationService
  # Arguments
  arg :required_param, type: String
  arg :optional_param, type: Integer, optional: true, default: 0

  # Steps
  step :validate
  step :perform
  step :cleanup, always: true

  # Outputs
  output :result, type: Hash

  private

  def validate
    errors.add(:required_param, "can't be blank") if required_param.blank?
  end

  def perform
    self.result = { success: true }
  end

  def cleanup
    # Always runs
  end
end
```

## Naming Conventions

- **Class name**: `ModelName::ActionVerb` (e.g., `User::Create`, `Order::Process`)
- **File path**: `app/services/model_name/action_verb.rb`
- **Step methods**: Use descriptive verbs (`validate`, `authorize`, `build_record`, `save`)

## Arguments

```ruby
# Required with type
arg :user_id, type: Integer

# Optional with default
arg :notify, type: [TrueClass, FalseClass], default: true

# Context argument (auto-passed to child services)
arg :current_user, type: User, optional: true, context: true

# Multiple allowed types
arg :id, type: [String, Integer]

# Proc default (evaluated at runtime)
arg :created_at, type: Time, default: -> { Time.current }
```

## Steps

```ruby
# Basic step
step :process

# Conditional execution
step :send_email, if: :should_notify?
step :skip_audit, unless: :production?

# Always run (even after errors, unless stop! or stop_immediately! are called)
step :cleanup, always: true

# Insertion points (for inheritance)
step :log_action, before: :save
step :broadcast, after: :save
```

## Outputs

```ruby
# Required output
output :user, type: User

# Optional output
output :metadata, type: Hash, optional: true

# With default
output :status, type: String, default: "completed"
```

## Error Handling

```ruby
# Add error (stops execution of next steps by default)
errors.add(:email, "is invalid")

# Add to base
errors.add(:base, "Something went wrong")
fail!("Something went wrong")  # Shorthand

# Copy from ActiveRecord model
errors.copy_from(user)

# Stop next steps without error (commits transaction)
stop!

# Stop with rollback
fail_immediately!("Critical error")
```

## Service Chaining

```ruby
# Run in same context (shared arguments, errors propagate, rollback propagate)
ChildService.with(self).run(param: value)

# Independent service (separate transaction)
OtherService.run(param: value)
```

## Configuration

```ruby
config use_transactions: true      # Wrap in DB transaction (default)
config raise_on_error: false       # Raise exception on error
config break_on_error: true        # Stop on error (default)
config rollback_on_error: true     # Rollback on error (default)
```

## Testing Pattern

```ruby
RSpec.describe ModelName::ActionName do
  describe ".run" do
    subject(:service) { described_class.run(params) }
    let(:params) { { required_param: "value" } }

    context "when successful" do
      it { is_expected.to be_successful }
      it { expect(service.result).to eq(expected) }
    end

    context "when validation fails" do
      let(:params) { { required_param: "" } }

      it { is_expected.to be_failed }
      it { is_expected.to have_error_on(:required_param) }
    end
  end
end
```

## Common Patterns

### CRUD Create
```ruby
class User::Create < CreateRecordService
  private

  def entity_class
    User
  end

  def filtered_params
    params.slice(:name, :email, :role)
  end
end
```

### With Authorization
```ruby
step :authorize
step :perform

def authorize
  fail!("Not authorized") unless current_user&.admin?
end
```

### With Callbacks
```ruby
before_service_run :log_start
after_service_run :log_finish
on_service_failure :notify_error
```

## Using dry-types

Light Services supports [dry-types](https://dry-rb.org/gems/dry-types) for advanced type validation and coercion.

### Arguments with dry-types

```ruby
class User::Create < ApplicationService
  # Strict types - must match exactly
  arg :name, type: Types::Strict::String
  
  # Coercible types - automatically convert values
  arg :age, type: Types::Coercible::Integer
  
  # Constrained types - add validation rules
  arg :email, type: Types::String.constrained(format: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i)
  
  # Enum types - restrict to specific values
  arg :status, type: Types::String.enum("active", "inactive", "pending"), default: "pending"
  
  # Array types with element validation
  arg :tags, type: Types::Array.of(Types::String), optional: true
  
  # Hash schemas with key transformation
  arg :metadata, type: Types::Hash.schema(key: Types::String).with_key_transform(&:to_sym), optional: true
end
```

### Outputs with dry-types

```ruby
class AI::Chat < ApplicationService
  # Strict type validation
  output :messages, type: Types::Strict::Array.of(Types::Hash)
  
  # Coercible types
  output :total_tokens, type: Types::Coercible::Integer
  
  # Constrained types (must be >= 0)
  output :cost, type: Types::Float.constrained(gteq: 0)
end
```

### Coercion Behavior

With coercible types, values are automatically converted:

```ruby
# String "25" is automatically converted to integer 25
service = User::Create.run(name: "John", age: "25")
service.age # => 25 (Integer, not String)
```

### Common dry-types Patterns

| Type | Description |
|------|-------------|
| `Types::Strict::String` | Must be a String, no coercion |
| `Types::Coercible::Integer` | Coerces to Integer (e.g., "25" → 25) |
| `Types::String.optional` | String or nil |
| `Types::String.enum("a", "b")` | Must be one of the listed values |
| `Types::Array.of(Types::String)` | Array where all elements are Strings |
| `Types::Hash.schema(key: Type)` | Hash with typed schema |
| `Types::Float.constrained(gteq: 0)` | Float >= 0 |

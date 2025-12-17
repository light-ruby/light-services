---
description: "Rules for managing Operandi - Ruby service objects with arguments, steps, and outputs"
globs: "**/services/**/*.rb"
alwaysApply: false
---

# Operandi Creation Rules

When creating or modifying services that inherit from `Operandi::Base` or `ApplicationService`, follow these patterns.

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

## Using Sorbet Runtime Types

Operandi supports [Sorbet runtime types](https://sorbet.org/docs/runtime) for type validation. Sorbet types **only validate** and do not coerce values.

### Arguments with Sorbet Types

```ruby
require "sorbet-runtime"

class User::Create < ApplicationService
  # Basic types
  arg :name, type: String
  arg :age, type: Integer
  
  # Nilable types
  arg :email, type: T.nilable(String), optional: true
  
  # Union types
  arg :status, type: T.any(String, Symbol)
  
  # Typed arrays
  arg :tags, type: T::Array[String], optional: true
  
  # Boolean type
  arg :active, type: T::Boolean, default: true
end
```

### Outputs with Sorbet Types

```ruby
class AI::Chat < ApplicationService
  # Typed array
  output :messages, type: T::Array[Hash]
  
  # Basic type
  output :total_tokens, type: Integer
  
  # Nilable type
  output :metadata, type: T.nilable(Hash), optional: true
end
```

### Validation Behavior

Sorbet types do NOT coerce values - they only validate:

```ruby
# This will RAISE an error (no coercion)
service = User::Create.run(name: "John", age: "25")
# => ArgTypeError: expected Integer, but got String

# This works correctly
service = User::Create.run(name: "John", age: 25)
service.age # => 25 (Integer)
```

### Common Sorbet Type Patterns

| Type | Description |
|------|-------------|
| `String` | Must be a String |
| `Integer` | Must be an Integer |
| `T.nilable(String)` | String or nil |
| `T.any(String, Symbol)` | String or Symbol |
| `T::Array[String]` | Array of Strings |
| `T::Hash[Symbol, String]` | Hash with Symbol keys and String values |
| `T::Boolean` | TrueClass or FalseClass |

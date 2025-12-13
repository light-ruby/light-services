# RuboCop Integration

Light Services provides custom RuboCop cops to help enforce best practices in your service definitions.

## Setup

Add this to your `.rubocop.yml`:

```yaml
require:
  - light/services/rubocop
```

## Available Cops

### LightServices/ArgumentTypeRequired

Ensures all `arg` declarations include a `type:` option.

```ruby
# bad
arg :user_id
arg :params, default: {}
arg :name, optional: true

# good
arg :user_id, type: Integer
arg :params, type: Hash, default: {}
arg :name, type: String, optional: true
```

### LightServices/OutputTypeRequired

Ensures all `output` declarations include a `type:` option.

```ruby
# bad
output :result
output :data, optional: true
output :count, default: 0

# good
output :result, type: Hash
output :data, type: Hash, optional: true
output :count, type: Integer, default: 0
```

### LightServices/StepMethodExists

Ensures all `step` declarations have a corresponding method defined in the same class.

```ruby
# bad
class MyService < ApplicationService
  step :validate
  step :process

  private

  def validate
    # only validate is defined, process is missing
  end
end

# good
class MyService < ApplicationService
  step :validate
  step :process

  private

  def validate
    # validation logic
  end

  def process
    # processing logic
  end
end
```

**Note:** This cop only checks for methods defined in the same file/class. It cannot detect methods inherited from parent classes. Use the `ExcludedSteps` option to exclude inherited steps:

```yaml
# .rubocop.yml
LightServices/StepMethodExists:
  ExcludedSteps:
    - initialize_entity
    - assign_attributes
    - authorize
    - save
    - log_action
```

This allows you to safely use inherited steps without triggering offenses:

```ruby
class User::Create < CreateService
  step :initialize_entity   # inherited - excluded via config
  step :assign_attributes   # inherited - excluded via config
  step :send_welcome_email  # defined below - will be checked

  private

  def send_welcome_email
    # ...
  end
end
```

## Configuration

You can configure these cops in your `.rubocop.yml`:

```yaml
LightServices/ArgumentTypeRequired:
  Enabled: true

LightServices/OutputTypeRequired:
  Enabled: true

LightServices/StepMethodExists:
  Enabled: true
  ExcludedSteps: []  # Add inherited step names here
```

To disable a cop for a specific file or directory:

```yaml
LightServices/ArgumentTypeRequired:
  Exclude:
    - 'spec/**/*'
    - 'test/**/*'
```

## Runtime vs Static Analysis

These RuboCop cops provide **static analysis** at lint time, complementing the **runtime validation** provided by the `require_type` configuration option.

| Feature | RuboCop Cops | Runtime `require_type` |
|---------|--------------|------------------------|
| When checked | Lint time (CI/editor) | Service load time |
| Catches issues | Before code runs | When class is loaded |
| Configurable per-service | No (always enforced) | Yes (`config require_type: false`) |

Using both together provides the best coverage:
- RuboCop catches issues in your editor/CI before code is committed
- Runtime validation catches any issues that slip through

## What's Next?

Learn more about testing your services:

[Next: Testing](testing.md)

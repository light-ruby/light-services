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

## Configuration

You can configure these cops in your `.rubocop.yml`:

```yaml
LightServices/ArgumentTypeRequired:
  Enabled: true

LightServices/OutputTypeRequired:
  Enabled: true
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

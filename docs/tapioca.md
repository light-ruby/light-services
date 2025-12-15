# Tapioca / Sorbet Integration

Light Services provides a [Tapioca](https://github.com/Shopify/tapioca) DSL compiler that generates RBI signatures for methods automatically created by the `arg` and `output` DSL macros. This enables full Sorbet type checking for your services.

## Features

When you use the `arg` or `output` keywords, Light Services dynamically generates methods at runtime:

```ruby
class CreateUser < ApplicationService
  arg :name, type: String
  arg :email, type: String, optional: true
  arg :role, type: [Symbol, String]
  
  output :user, type: User
end
```

The Tapioca compiler generates RBI signatures for these methods:

```rbi
# sorbet/rbi/dsl/create_user.rbi
# typed: true

class CreateUser
  sig { returns(String) }
  def name; end

  sig { returns(T::Boolean) }
  def name?; end

  sig { returns(T.nilable(String)) }
  def email; end

  sig { returns(T::Boolean) }
  def email?; end

  sig { returns(T.any(Symbol, String)) }
  def role; end

  sig { returns(T::Boolean) }
  def role?; end

  sig { returns(User) }
  def user; end

  sig { returns(T::Boolean) }
  def user?; end

  private

  sig { params(value: String).returns(String) }
  def name=(value); end

  sig { params(value: T.nilable(String)).returns(T.nilable(String)) }
  def email=(value); end

  sig { params(value: T.any(Symbol, String)).returns(T.any(Symbol, String)) }
  def role=(value); end

  sig { params(value: User).returns(User) }
  def user=(value); end
end
```

## Setup

### 1. Install Tapioca

Add Tapioca to your Gemfile:

```ruby
group :development do
  gem "tapioca", require: false
end
```

Then run:

```bash
bundle install
bundle exec tapioca init
```

### 2. Generate RBI Files

The Light Services compiler is automatically discovered by Tapioca. Generate RBI files with:

```bash
bundle exec tapioca dsl
```

This will create RBI files in `sorbet/rbi/dsl/` for all your services.

### 3. Re-generate After Changes

After adding or modifying `arg`/`output` declarations, regenerate the RBI files:

```bash
bundle exec tapioca dsl LightServices
```

## Type Mappings

### Ruby Types

Standard Ruby types are mapped directly:

| Ruby Type | Sorbet Type |
|-----------|-------------|
| `String` | `::String` |
| `Integer` | `::Integer` |
| `Float` | `::Float` |
| `Hash` | `::Hash` |
| `Array` | `::Array` |
| `Symbol` | `::Symbol` |
| `User` (custom) | `::User` |

### Boolean Types

Boolean types are mapped to `T::Boolean`:

```ruby
arg :active, type: [TrueClass, FalseClass]
# Generates: sig { returns(T::Boolean) }
```

### Union Types

Multiple types create union types:

```ruby
arg :id, type: [String, Integer]
# Generates: sig { returns(T.any(::String, ::Integer)) }
```

### Optional Types

Optional arguments/outputs are wrapped in `T.nilable`:

```ruby
arg :nickname, type: String, optional: true
# Generates: sig { returns(T.nilable(::String)) }
```

### Dry-Types

If you use [dry-types](https://dry-rb.org/gems/dry-types/), they are mapped to their primitive Ruby types:

| Dry Type | Sorbet Type |
|----------|-------------|
| `Types::String` | `::String` |
| `Types::Strict::String` | `::String` |
| `Types::Integer` | `::Integer` |
| `Types::Bool` | `T::Boolean` |
| `Types::Array` | `::Array` |
| `Types::Hash` | `::Hash` |
| `Types::Date` | `::Date` |
| `Types::Time` | `::Time` |
| `Types::DateTime` | `::DateTime` |
| `Types::Decimal` | `::BigDecimal` |
| `Types::Any` | `T.untyped` |

Parameterized dry-types (e.g., `Types::Array.of(String)`) are mapped to their base type.

## Generated Methods

For each `arg` or `output`, three methods are generated:

| Method | Return Type | Visibility |
|--------|-------------|------------|
| `name` | The declared type | public |
| `name?` | `T::Boolean` | public |
| `name=` | The declared type | **private** |

## Inheritance

The compiler handles inherited arguments and outputs. If a child service inherits from a parent, the RBI will include methods for both parent and child fields.

## Troubleshooting

### RBI files not generated

Ensure Light Services is properly loaded in your application. The compiler only runs if `Light::Services::Base` is defined.

### Types showing as `T.untyped`

This happens when:
- No `type:` option is specified for the argument/output
- The type cannot be resolved (e.g., undefined constant)

### Custom type mappings

If you need custom dry-types mappings, you can extend the `DRY_TYPE_MAPPINGS` constant in the compiler or open an issue to add common mappings.

## See Also

- [Ruby LSP Integration](ruby-lsp.md) - Editor integration without Sorbet
- [Arguments](arguments.md) - Full `arg` DSL documentation  
- [Outputs](outputs.md) - Full `output` DSL documentation

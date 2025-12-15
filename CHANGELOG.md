# Changelog

## Unreleased

### Added

- Add Cursor rules
- Add `successful?` as an alias for `success?`
- Add RuboCop cop `PreferFailMethod` to detect `errors.add(:base, "message")` and suggest using `fail!("message")` instead

### Breaking changes

- Service runs steps with `always: true` after `fail_immediately!` was called

## 3.1.2 (2025-12-13)

### Added

- Add `fail!` and `fail_immediately!` helpers

### Changed

- Split `config.require_type` into `config.require_arg_type` and `config.require_output_type`

## 3.1.1 (2025-12-13)

### Added

- Better IDE support for callbacks DSL

## 3.1.0 (2025-12-13)

### Breaking changes

- Enforce arguments and output types by default. Use `config.require_arg_type = false` and `config.require_output_type = false` to disable this behavior. The convenience setter `config.require_type = false` sets both options at once for backward compatibility.

### Added

- `stop!` and `stopped?` methods for early exit (renamed from `done!` and `done?`)
- `stop_immediately!` method for immediate execution halt within the current step
- `done!` and `done?` are deprecated, but remain available as aliases for backward compatibility
- Ruby LSP support with step navigation and indexing
- Rubocop cops `StepMethodExists`, `ConditionMethodExists`, `DslOrder`, `MissingPrivateKeyword`, `NoDirectInstantiation`, `ArgumentTypeRequired`, `OutputTypeRequired`, `DeprecatedMethods`
- Comprehensive YARD documentation

## 3.0.0 (2025-12-12)

### Breaking changes

- Removed support for symbol types (e.g., `:array`, `:hash`, `:boolean`). Use Ruby classes (e.g., `Array`, `Hash`, `[TrueClass, FalseClass]`) or dry-types
- Removed `benchmark: true` option
- Removed `verbose: true` option
- Bumped minimum supported Ruby version to **3.0**.
- Removed `errors.copy_to`

### Added

- Output type validation
- dry-types support for arguments and outputs (with coercion and constraints)
- Callback system (service + step callbacks)
- Built-in RSpec matchers for services
- Name validation for arguments, steps, and outputs
- `run` method fallback when no steps are defined

### Documentation

- Documentation moved into this repository and refreshed to match v3 behavior

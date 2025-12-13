# Changelog

## Unreleased

### Breaking changes

- Enforce arguments and output types by default. Add `config.require_type = false` to your config to disable this behavior.

### Added

- `stop!` and `stopped?` methods for early exit (renamed from `done!` and `done?`)
- `stop_immediately!` method for immediate execution halt within the current step
- `done!` and `done?` remain available as aliases for backward compatibility

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

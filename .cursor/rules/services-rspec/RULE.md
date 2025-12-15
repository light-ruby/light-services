---
description: "Rules for writing RSpec tests for Light Services - testing arguments, steps, outputs, and behavior"
globs: "**/spec/services/*_spec.rb"
alwaysApply: false
---

# Light Services RSpec Testing Rules

When writing RSpec tests for services that inherit from `Light::Services::Base` or `ApplicationService`, follow these patterns.

## Setup

Add to `spec/spec_helper.rb` or `spec/rails_helper.rb`:

```ruby
require "light/services/rspec"
```

## Test Structure

Always structure test files in this order:
1. Describe block with service class
2. DSL definition tests (arguments, outputs, steps)
3. Behavior tests (`.run` scenarios)
4. Edge cases and error handling

```ruby
# spec/services/model_name/action_name_spec.rb
RSpec.describe ModelName::ActionName do
  # DSL Definition Tests
  describe "arguments" do
    it { expect(described_class).to define_argument(:required_param).with_type(String) }
    it { expect(described_class).to define_argument(:optional_param).with_type(Integer).optional.with_default(0) }
  end

  describe "outputs" do
    it { expect(described_class).to define_output(:result).with_type(Hash) }
  end

  describe "steps" do
    it { expect(described_class).to define_steps_in_order(:validate, :perform, :cleanup) }
    it { expect(described_class).to define_step(:cleanup).with_always(true) }
  end

  # Behavior Tests
  describe ".run" do
    subject(:service) { described_class.run(params) }
    let(:params) { { required_param: "value" } }

    context "when successful" do
      it { is_expected.to be_successful }
      it { expect(service.result).to eq(expected_result) }
    end

    context "when validation fails" do
      let(:params) { { required_param: "" } }
      it { is_expected.to be_failed }
      it { is_expected.to have_error_on(:required_param) }
    end
  end
end
```

## Naming Conventions

- **File path**: `spec/services/model_name/action_name_spec.rb`
- **Describe block**: Use the service class name directly
- **Context blocks**: Start with "when" or "with" to describe conditions
- **It blocks**: Be specific about what is being tested

## DSL Matchers

### Arguments

```ruby
# Basic argument
it { expect(described_class).to define_argument(:id) }

# With type (single or multiple)
it { expect(described_class).to define_argument(:id).with_type([String, Integer]) }

# Optional with default
it { expect(described_class).to define_argument(:status).optional.with_default("pending") }

# Context argument
it { expect(described_class).to define_argument(:current_user).with_context }
```

### Outputs

```ruby
# Basic output
it { expect(described_class).to define_output(:user) }

# With type
it { expect(described_class).to define_output(:user).with_type(User) }

# Optional with default
it { expect(described_class).to define_output(:count).optional.with_default(0) }
```

### Steps

```ruby
# Basic step
it { expect(described_class).to define_step(:validate) }

# With always flag
it { expect(described_class).to define_step(:cleanup).with_always(true) }

# Conditional steps
it { expect(described_class).to define_step(:notify).with_if(:should_notify?) }
it { expect(described_class).to define_step(:skip_audit).with_unless(:production?) }

# Multiple steps in order
it { expect(described_class).to define_steps_in_order(:validate, :process, :save) }
```

## Behavior Testing

### Success Cases

```ruby
describe ".run" do
  subject(:service) { described_class.run(params) }
  let(:params) { { name: "John", email: "john@example.com" } }

  it { is_expected.to be_successful }
  it { expect(service.user).to be_persisted }
  it { expect(service.user.name).to eq("John") }
end
```

### Failure Cases

```ruby
context "when validation fails" do
  let(:params) { { name: "", email: "" } }

  it { is_expected.to be_failed }
  it { is_expected.to have_error_on(:name) }
  it { is_expected.to have_error_on(:email).with_message("can't be blank") }
  it { is_expected.to have_errors_on(:name, :email) }
end
```

### Warnings

```ruby
it { expect(service.warnings?).to be true }
it { is_expected.to have_warning_on(:format).with_message("format is deprecated") }
```

### run! vs run

```ruby
# .run returns failed service
it { expect(described_class.run(amount: -100)).to be_failed }

# .run! raises exception
it { expect { described_class.run!(amount: -100) }.to raise_error(Light::Services::Error, /must be positive/) }
```

### Config Overrides

```ruby
# With raise_on_error
expect { described_class.run({ invalid: true }, { raise_on_error: true }) }
  .to raise_error(Light::Services::Error)

# With use_transactions: false
service = described_class.with(use_transactions: false).run(params)
```

## Database Testing

```ruby
# Record creation
expect { described_class.run(params) }.to change(User, :count).by(1)
expect(service.user).to be_persisted

# Transaction rollback on failure
allow_any_instance_of(ChildService).to receive(:perform) do |svc|
  svc.errors.add(:base, "Simulated failure")
end
expect { described_class.run(params) }.not_to change(Order, :count)
```

## Service Chaining

```ruby
# Verify context sharing
expect(ChildService).to receive(:with).and_call_original
described_class.run(current_user: current_user, data: data)

# Error propagation from child
allow_any_instance_of(ChildService).to receive(:validate) { |svc| svc.fail!("Child error") }
expect(described_class.run(current_user: current_user, data: data))
  .to have_error_on(:base).with_message("Child error")
```

## Conditional Steps

```ruby
# When condition is true
expect { described_class.run(send_notification: true, email: "x@example.com") }
  .to have_enqueued_mail(UserMailer, :notification)

# When condition is false
expect { described_class.run(send_notification: false, email: "x@example.com") }
  .not_to have_enqueued_mail(UserMailer, :notification)
```

## Early Exit (stop!)

```ruby
existing_user = create(:user, email: "exists@example.com")
service = described_class.run(email: existing_user.email)

expect { service }.not_to change(User, :count)
expect(service.user).to eq(existing_user)
expect(service).to be_successful
expect(service.stopped?).to be true
```

## Argument Validation

```ruby
# Required argument nil
expect { described_class.run(name: nil) }.to raise_error(Light::Services::ArgTypeError)

# Wrong type
expect { described_class.run(name: 123) }.to raise_error(Light::Services::ArgTypeError, /must be a String/)

# Optional accepts nil
expect(described_class.run(name: "John", nickname: nil)).to be_successful

# Default values
expect(described_class.run(name: "John").status).to eq("pending")
```

## External Services

```ruby
let(:stripe_client) { instance_double(Stripe::PaymentIntent, id: "pi_123") }

before { allow(Stripe::PaymentIntent).to receive(:create).and_return(stripe_client) }

it "processes payment" do
  service = described_class.run(amount: 1000, card_token: "tok_visa")
  expect(service).to be_successful
  expect(service.payment_intent_id).to eq("pi_123")
end

context "when external fails" do
  before { allow(Stripe::PaymentIntent).to receive(:create).and_raise(Stripe::CardError.new("Card declined", nil, nil)) }

  it { expect(service).to be_failed }
  it { expect(service).to have_error_on(:payment).with_message("Card declined") }
end
```

## Optional Tracking

### Step Execution

```ruby
# app/services/application_service.rb
class ApplicationService < Light::Services::Base
  output :executed_steps, type: Array, default: -> { [] }
  after_step_run { |service, step| service.executed_steps << step }
end
```

### Callback Tracking

```ruby
class ApplicationService < Light::Services::Base
  output :callback_log, type: Array, default: -> { [] }
  before_service_run { |s| s.callback_log << :before_service_run }
  after_service_run  { |s| s.callback_log << :after_service_run }
  on_service_success { |s| s.callback_log << :on_service_success }
  on_service_failure { |s| s.callback_log << :on_service_failure }
end
```

## Shared Examples

### Create Service

```ruby
RSpec.shared_examples "a create service" do |model_class|
  let(:valid_attributes) { attributes_for(model_class.name.underscore.to_sym) }
  let(:current_user) { create(:user) }

  it { expect { described_class.run(current_user: current_user, attributes: valid_attributes) }.to change(model_class, :count).by(1) }
  it { expect(described_class.run(current_user: current_user, attributes: valid_attributes).record).to be_persisted }
  it { expect(described_class.run(current_user: current_user, attributes: valid_attributes)).to be_successful }
end
```

### Authorized Service

```ruby
RSpec.shared_examples "an authorized service" do
  context "without current_user" do
    let(:current_user) { nil }
    it { is_expected.to be_failed }
    it { is_expected.to have_error_on(:authorization) }
  end

  context "with unauthorized user" do
    let(:current_user) { create(:user, role: :guest) }
    it { is_expected.to be_failed }
    it { is_expected.to have_error_on(:authorization) }
  end
end
```

## Test Helpers

```ruby
module ServiceHelpers
  def expect_service_success(service)
    expect(service).to be_successful, -> { "Expected success but got errors: #{service.errors.to_h}" }
  end

  def expect_service_failure(service, key = nil)
    expect(service).to be_failed
    expect(service.errors[key]).to be_present if key
  end
end

RSpec.configure { |config| config.include ServiceHelpers, type: :service }
```

## Common Matchers Reference

| Matcher | Description |
|---------|-------------|
| `be_successful` | Service completed without errors |
| `be_failed` | Service has errors |
| `have_error_on(:key)` | Has error on specific key |
| `have_error_on(:key).with_message(msg)` | Error with specific message |
| `have_errors_on(:key1, :key2)` | Has errors on multiple keys |
| `have_warning_on(:key)` | Has warning on specific key |
| `define_argument(:name)` | Service defines argument |
| `define_output(:name)` | Service defines output |
| `define_step(:name)` | Service defines step |
| `define_steps(:a, :b, :c)` | Service defines all steps (any order) |
| `define_steps_in_order(:a, :b, :c)` | Service defines steps in order |
| `execute_step(:name)` | Step was executed (tracking required) |
| `skip_step(:name)` | Step was skipped (tracking required) |
| `trigger_callback(:name)` | Callback was triggered (tracking required) |

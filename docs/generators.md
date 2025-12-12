# Rails Generators

Light Services includes Rails generators to help you quickly set up and create services in your Rails application. These generators follow Rails conventions and integrate seamlessly with your Rails workflow.

## Install Generator

The install generator sets up Light Services in your Rails application by creating the base `ApplicationService` class and configuration files.

### Usage

```bash
bin/rails generate light_services:install
```

### What It Creates

The install generator creates the following files:

1. **`app/services/application_service.rb`** - Base service class for your application
   ```ruby
   class ApplicationService < Light::Services::Base
     # Add common arguments, callbacks, or helpers shared across all services.
     #
     # Example: Add a context argument for the current user
     # arg :current_user, type: User, optional: true, context: true
   end
   ```

2. **`config/initializers/light_services.rb`** - Configuration file (unless `--skip-initializer` is used)
   This file contains the global configuration for Light Services in your Rails application.

3. **`spec/services/application_service_spec.rb`** - RSpec test file (if RSpec is detected and `--skip-spec` is not used)

### Options

- `--skip-initializer` - Skip creating the initializer file
- `--skip-spec` - Skip creating the spec file

### Examples

```bash
# Standard installation
bin/rails generate light_services:install

# Skip initializer
bin/rails generate light_services:install --skip-initializer

# Skip spec file
bin/rails generate light_services:install --skip-spec
```

## Service Generator

The service generator creates a new service class that inherits from `ApplicationService`. It supports namespaced services and can pre-populate arguments, steps, and outputs.

### Usage

```bash
bin/rails generate light_services:service NAME [options]
```

### What It Creates

The service generator creates:

1. **Service file** - `app/services/{name}.rb`
2. **Spec file** - `spec/services/{name}_spec.rb` (if RSpec is detected and `--skip-spec` is not used)

### Options

- `--args` - List of arguments for the service (space-separated)
- `--steps` - List of steps for the service (space-separated)
- `--outputs` - List of outputs for the service (space-separated)
- `--skip-spec` - Skip creating the spec file
- `--parent` - Parent class (default: `ApplicationService`)

### Examples

#### Basic Service

Create a simple service without any predefined structure:

```bash
bin/rails generate light_services:service user/create
```

This creates:
```ruby
# app/services/user/create.rb
class User::Create < ApplicationService
  # step :step_a
  # step :step_b

  private

  # def step_a
  #   # TODO: Implement service logic
  # end

  # def step_b
  #   # TODO: Implement service logic
  # end
end
```

#### Service with Arguments, Steps, and Outputs

Create a fully structured service:

```bash
bin/rails generate light_services:service CreateOrder \
  --args=user product quantity \
  --steps=validate_stock create_order send_confirmation \
  --outputs=order
```

This creates:
```ruby
# app/services/create_order.rb
class CreateOrder < ApplicationService
  # Arguments
  arg :user
  arg :product
  arg :quantity

  # Steps
  step :validate_stock
  step :create_order
  step :send_confirmation

  # Outputs
  output :order

  private

  def validate_stock
    # TODO: Implement validate_stock
  end

  def create_order
    # TODO: Implement create_order
  end

  def send_confirmation
    # TODO: Implement send_confirmation
  end
end
```

#### Namespaced Service

Create a service within a namespace:

```bash
bin/rails generate light_services:service payment/process \
  --args=order payment_method \
  --steps=validate_payment charge_card update_order \
  --outputs=transaction
```

This creates:
```ruby
# app/services/payment/process.rb
class Payment::Process < ApplicationService
  # Arguments
  arg :order
  arg :payment_method

  # Steps
  step :validate_payment
  step :charge_card
  step :update_order

  # Outputs
  output :transaction

  private

  def validate_payment
    # TODO: Implement validate_payment
  end

  def charge_card
    # TODO: Implement charge_card
  end

  def update_order
    # TODO: Implement update_order
  end
end
```

#### Custom Parent Class

Create a service that inherits from a custom parent class:

```bash
bin/rails generate light_services:service admin/reports/generate \
  --parent=AdminService \
  --args=start_date end_date \
  --steps=fetch_data generate_report \
  --outputs=report
```

## RSpec Integration

Both generators automatically detect if RSpec is installed in your Rails application by checking for the presence of the `spec/` directory. If RSpec is detected, the generators will create corresponding spec files with basic test structure.

### Example Spec File

```ruby
# spec/services/user/create_spec.rb
require "rails_helper"

RSpec.describe User::Create do
  describe ".run" do
    it "creates a user" do
      service = described_class.run(...)
      expect(service).to be_success
    end
  end
end
```

You can skip spec file generation with the `--skip-spec` option:

```bash
bin/rails generate light_services:service user/create --skip-spec
```

## Best Practices

1. **Run the install generator first** - Always run `light_services:install` before creating individual services to set up the base `ApplicationService` class.

2. **Use namespaces** - Organize related services under namespaces (e.g., `User::Create`, `Payment::Process`) to keep your services organized.

3. **Start with structure** - Use `--args`, `--steps`, and `--outputs` options to create a skeleton for your service, then fill in the implementation.

4. **Keep it simple** - Don't over-specify. If you're not sure about the exact steps, create a basic service and add them as you develop.

5. **Follow conventions** - Use descriptive names for services that indicate the action being performed (e.g., `CreateOrder`, `User::Authenticate`, `Payment::Refund`).

## Next Steps

After generating your services, learn more about:

- [Arguments](arguments.md) - Define and validate service inputs
- [Steps](steps.md) - Organize service logic into steps
- [Outputs](outputs.md) - Define service outputs
- [Testing](testing.md) - Write comprehensive tests for your services

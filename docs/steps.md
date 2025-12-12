# Steps

Steps are the core components of a service, each representing a unit of work executed in sequence when the service is called.

## TL;DR

- Define steps using the `step` keyword within the service class
- Use `if` and `unless` options for conditional steps
- Inherit steps from parent classes
- Inject steps into the execution flow with `before` and `after` options
- Ensure steps always run with the `always: true` option
- Retry steps with the `retry` option \[In Development]

```ruby
class GeneralParserService < ApplicationService
  step :create_browser, unless: :browser
  step :parse_content
  step :quit_browser, always: true
end

class ParsePage < GeneralParserService
  step :parse_additional_content, after: :parse_content
end
```

## Define Steps

Steps are declared using the `step` keyword in your service class.

```ruby
class User::Charge < ApplicationService
  step :authorize
  step :charge
  step :send_email_receipt

  private

  def authorize
    # ...
  end

  def charge
    # ...
  end

  def send_email_receipt
    # ...
  end
end
```

## Conditional Steps

Steps can be conditional, executed based on specified conditions using the `if` or `unless` keywords.

```ruby
class User::Charge < ApplicationService
  step :authorize
  step :charge
  step :send_email_receipt, if: :send_receipt?

  # ...

  def send_receipt?
    rand(2).zero?
  end
end
```

This feature works well with argument predicates.

```ruby
class User::Charge < ApplicationService
  arg :send_receipt, type: :boolean, default: true

  step :send_email_receipt, if: :send_receipt?

  # ...
end
```

### Using Procs for Conditions

You can also use Procs (lambdas) for inline conditions:

```ruby
class User::Charge < ApplicationService
  arg :amount, type: :float

  step :apply_discount, if: -> { amount > 100 }
  step :charge
  step :send_large_purchase_alert, if: -> { amount > 1000 }

  # ...
end
```

{% hint style="info" %}
Using Procs can make simple conditions more readable, but for complex logic, prefer extracting to a method.
{% endhint %}

## Inheritance

Steps are inherited from parent classes, making it easy to build upon existing services.

```ruby
# UpdateRecordService
class UpdateRecordService < ApplicationService
  arg :record, type: ApplicationRecord
  arg :attributes, type: Hash

  step :authorize
  step :update_record
end
```

```ruby
# User::Update inherited from UpdateRecordService
class User::Update < UpdateRecordService
  # Arguments and steps are inherited from UpdateRecordService
end
```

## Injecting Steps into Execution Flow

Steps can be injected at specific points in the execution flow using `before` and `after` options.

Let's enhance the previous example by adding a step to send a notification after updating the record.

```ruby
# User::Update inherited from UpdateRecordService
class User::Update < UpdateRecordService
  step :log_action, before: :authorize
  step :send_notification, after: :update_record

  private

  def log_action
    # ...
  end

  def send_notification
    # ...
  end
end
```

Combine this with `if` and `unless` options for more control.

```ruby
step :send_notification, after: :update_record, if: :send_notification?
```

{% hint style="info" %}
By default, if neither `before` nor `after` is specified, the step is added at the end of the execution flow.
{% endhint %}

## Always Running Steps

To ensure certain steps run regardless of previous step outcomes, use the `always: true` option. This is particularly useful for cleanup tasks, error logging, etc.

```ruby
class ParsePage < ApplicationService
  arg :url, type: :string

  step :create_browser
  step :parse_content
  step :quit_browser, always: true

  private

  attr_accessor :browser

  def create_browser
    self.browser = Watir::Browser.new
  end

  def parse_content
    # ...
  end

  def quit_browser
    browser&.quit
  end
end
```

## Early Exit with `done!`

Use `done!` to stop executing remaining steps without adding an error. This is useful when you've completed the service's goal early and don't need to run subsequent steps.

```ruby
class User::FindOrCreate < ApplicationService
  arg :email, type: :string

  step :find_existing_user
  step :create_user
  step :send_welcome_email

  output :user

  private

  def find_existing_user
    self.user = User.find_by(email:)
    done! if user # Skip remaining steps if user already exists
  end

  def create_user
    self.user = User.create!(email:)
  end

  def send_welcome_email
    # Only runs for newly created users
    Mailer.welcome(user).deliver_later
  end
end
```

You can check if `done!` was called using `done?`:

```ruby
def some_step
  done!
  
  # This code still runs within the same step
  puts "Done? #{done?}" # => "Done? true"
end

def next_step
  # This step will NOT run because done! was called
end
```

{% hint style="info" %}
`done!` only stops subsequent steps from running. Code after `done!` within the same step method will still execute.
{% endhint %}

## Removing Inherited Steps

When inheriting from a parent service, you can remove steps using `remove_step`:

```ruby
class UpdateRecordService < ApplicationService
  step :authorize
  step :validate
  step :update_record
  step :send_notification
end

class InternalUpdate < UpdateRecordService
  # Remove authorization for internal system updates
  remove_step :authorize
  remove_step :send_notification
end
```

## Retry Failed Steps

{% hint style="warning" %}
This feature is planned for a future release and is not yet implemented.
{% endhint %}

Steps will be able to be retried a specified number of times before giving up, using the `retry` option.

```ruby
class ParsePage < ApplicationService
  step :parse_head, retry: true # Retry 3 times by default, no delay between retries
  step :parse_body, retry: { times: 3, delay: 1.second }
end
```

# What's Next?

Next step is to learn about outputs. Outputs are the results of a service, returned upon completion of service execution.

[Next: Outputs](outputs.md)


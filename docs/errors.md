# Handling Errors in Light Services

Errors are a natural part of every application. In this guide, we'll explore how to handle errors within Light Services, drawing parallels to ActiveModel errors.

## Error Structure

Light Service errors follow a structure similar to ActiveModel errors. Here's a simplified example:

```ruby
{
  email: ["must be a valid email"],
  password: ["is too short", "must contain at least one number"]
}
```

## Adding Errors

To add an error to your service, use the `errors.add` method.

{% hint style="info" %}
By default, adding an error marks the service as failed, preventing subsequent steps from executing. This behavior can be customized in the configuration for individual services and errors.
{% endhint %}

```ruby
class ParsePage < ApplicationService
  # Arguments
  arg :url, type: :string
  # ...

  # Steps
  step :validate
  step :parse
  # ...

  private

  def validate
    # Multiple errors can be added with the same key
    errors.add(:url, "must be a valid URL") unless url.match?(URI::DEFAULT_PARSER.make_regexp)
    errors.add(:url, "must be a secure link") unless url.start_with?("https")
  end

  # ...
end
```

## Reading Errors

To check if a service has errors, you can use the `#failed?` method. You can also use methods like `errors.any?` to inspect errors.

```ruby
class ParsePage < ApplicationService
  def parse
    nodes.each do |node|
      if node.blank?
        errors.add(:base, "Node #{node} is blank")
      else
        parse_node(node)
      end
    end

    if failed? # or errors.any?
      puts "Not all nodes were parsed"
    end
  end
end
```

You can access errors outside the service using the `#errors` method.

```ruby
service = ParsePage.run(url: "rubygems")

if service.failed?
  puts service.errors
  puts service.errors[:url]
  puts service.errors.to_h # Returns errors as a hash
end
```

## Adding Warnings

Sometimes, you may want to add a warning instead of an error. Warnings are similar to errors but they do not mark the service as failed, do not stop execution, and do not roll back the transaction.

```ruby
class ParsePage < ApplicationService
  def validate
    errors.add(:url, "must be a valid URL") unless url.match?(URI::DEFAULT_PARSER.make_regexp)
    warnings.add(:url, "should be a secure link") unless url.start_with?("https")
  end
end
```

```ruby
service = ParsePage.run(url: "http://rubygems.org")

if service.warnings.any?
  puts service.warnings
  puts service.warnings[:url]
  puts service.warnings.to_h # Returns warnings as a hash
end
```

## Copying Errors

### From ActiveRecord Models

Use `errors.copy_from` (or its alias `errors.from_record`) to copy errors from an ActiveRecord model:

```ruby
class User::Create < ApplicationService
  def create_user
    self.user = User.new(attributes)
    
    unless user.save
      errors.copy_from(user) # Copies all validation errors from the user model
    end
  end
end
```

### From Another Service

Copy errors from a child service that wasn't run in the same context:

```ruby
class Order::Process < ApplicationService
  def process_payment
    payment_service = Payment::Charge.run(amount:, card:)
    
    if payment_service.failed?
      errors.copy_from(payment_service)
    end
  end
end
```

### To External Objects

Export errors to an ActiveRecord model or hash using `errors.copy_to`:

```ruby
def validate_with_model
  if errors.any?
    errors.copy_to(record) # Copies service errors to the record's errors
  end
end
```

## Converting Errors to Hash

Use `errors.to_h` to get a hash representation of all errors:

```ruby
service = User::Create.run(email: "invalid")

if service.failed?
  service.errors.to_h
  # => { email: ["is invalid"], password: ["can't be blank"] }
end
```

## Per-Message Options

When adding errors, you can control behavior on a per-message basis:

### Control Break Behavior

```ruby
def validate
  # This error won't stop subsequent steps from running
  errors.add(:warning_field, "has a minor issue", break: false)
  
  # This error WILL stop execution (default behavior)
  errors.add(:critical_field, "is completely invalid")
end
```

### Control Rollback Behavior

```ruby
def process
  # This error won't trigger a transaction rollback
  errors.add(:notification, "failed to send", rollback: false)
  
  # This error WILL rollback (default behavior when use_transactions is true)
  errors.add(:payment, "failed to process")
end
```

## Checking for Errors and Warnings

Light Services provides convenient methods to check error/warning states:

```ruby
service = MyService.run(args)

# Check if service has any errors
service.failed?   # => true/false
service.success?  # => true/false (opposite of failed?)
service.errors?   # => true/false (same as errors.any?)

# Check if service has any warnings
service.warnings? # => true/false (same as warnings.any?)
```

By following these guidelines, you can effectively manage errors and warnings in Light Services, ensuring a smoother and more robust application experience.

## What's next?

Congratulations! Boring stuff is done. Now you can learn some best practices and start using Light Service in your projects.

[Next: Best Practices](best-practices.md)


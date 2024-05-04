# 🚀 Light Services

An implementation of the Service Object pattern for Ruby and Rails applications.

## 👀 Table of Contents
1. [Simple Example](#simple-example)
2. [Usage](#usage)
   1. [Arguments](#arguments)
   2. [Steps](#steps)
   3. [Outputs](#outputs)
   4. [Context](#context)
3. [Complex Example](#complex-example)
4. [More Examples](#more-examples)

## 💪 Features

1. Ability to define `arguments`, `steps`, and `outputs`
1. Isolated behavior of each service object
1. Errors raise to stop processing subsequent steps
1. Wrapping actions in database transactions
1. Ability to pass context to child service objects
1. Framework agnostic
1. 100% test coverage

## ❌ Problems

This gem was initially intended for internal use and has several issues:

1. The gem is not well-documented
1. The code lacks comments

## Installation

Add this line to your application's Gemfile:

```ruby
gem "light-services", "~> 2.0" 
```

## Simple Example

### Send Notification

Create a basic service object that sends a notification to a user. 

```ruby
class User::SendNotification < ApplicationService
  # Arguments
  arg :user, type: User
  arg :text, type: :string

  # Steps
  step :validate_user
  step :validate_text
  step :send_notification
  
  # Outputs
  output :response

  private

  def validate_user
    return if user.active?
    
    errors.add(:user, "isn't active")
  end

  def validate_text
    return if text.present?

    errors.add(:text, "must be present")
  end

  def send_notification
    self.response = ExternalAPI.send_message(...)
  rescue ExternalAPI::Error
    errors.add(:base, "External API doesn't work")
  end
end
```

## Usage

### Arguments

Pass arguments into the service object as shown:

**How to define arguments:**
```ruby
class User::SendNotification < ApplicationService
  # Required argument
  arg :user, type: User
  
  # Optional argument
  arg :device, type: Device, optional: true
  
  # Argument with default value
  arg :text, type: :string, default: "Hello, how are you?"
  
  # Argument with multiple allowed types
  arg :retry, type: [TrueClass, FalseClass], default: false
  
  # Argument which will be automatically passed into child components
  arg :provider, type: Provider, context: true
end
```

**How to pass arguments from a controller:**
```ruby
class UsersController
  def send_notification
    service = User::SendNotification.run(user: User.first, provider: Provider.first)
    # ...
  end
end
```

**Passing arguments and context from parent to child service object:**
```ruby
class User::Update
  # Arguments
  arg :user, type: User, context: true

  # Steps
  # ...
  step :send_notification

  private

  # ...

  def send_notification
    User::SendNotification
      .with(self) # Specifies the current service object as parent, passing all context arguments to a child service object
      .run(text: "Your profile was updated") # No need to pass `user` as it's a context argument
  end
end
```

### Steps

Steps are a bit more powerful than they appear.

```ruby
class User::Charge
  # Run step only when condition meets
  step :create_payment_account, unless: :payment_account?
  
  # Run step only when condition meets
  step :charge_credit_card, if: :pay_with_credit_card?
  
  # Run step after other step
  step :update_payment_account, after: :create_payment_account
  
  # Or before
  step :save_information, before: :log_action
end
```

### Outputs

Outputs are straightforward.

```ruby
class User::Charge
  # Simple output
  output :payment
  
  # Output with initial value
  output :items, default: []
end
```

### Context

The context specifies the relationship between parent and child service objects.

What the context does:
1. Tells the parent service object to pass context arguments to a child service object.
1. Informs the parent service object to also fail when the child service object fails (this is customizable).

```ruby
class User::Charge
  # Arguments
  arg :user, type: User, context: true
  arg :cents, type: Integer
  
  # ...
  
  private
  
  # ...
  
  def send_notification
    # Run service object w/o any context
    User::SendNotification
      .run(user: user, text: "...")
  
    # Run service object and specify current one as a parent
    User::SendNotification
      .with(self)
      .run(text: "...")
      
    # Run service object with context but don't load errors from the child service object
    service = User::SendNotification
      .with(self, load_errors: false)
      .run(text: "...")
      
    if service.failed?
      # That's ok. Process it somehow...
    end
  end
end
```

## Complex Example

### Record Creation

Explore a more intricate example of creating database records.

**Here is an example of controller (pretty thin, yeah? but we can make it even thinner):**
```ruby
class ContactsController < ApplicationController
  # ...

  def create
    service = Contact::Create.run(service_args)
    
    if service.success?
      render locals: { contact: service.contact }, status: :ok
    else
      render "shared/errors", locals: { service: service }, status: :bad_request
    end
  end

  # ...
end
```

**Then, let's create a service object (no way, it couldn't be so simple):**
```ruby
class Contact::Create < CreateService
  # We create alias just for a better readability
  # so that we can call `service.contact` instead of `service.record`  
  alias contact record
  
  private
  
  def filtered_params
    params.require(:contact).permit(:name, :phone)
  end
end
```

**Let's check what logic we put into `CreateService`:**
```ruby
class CreateService < ApplicationService
  # Arguments
  arg :attributes, type: Hash, optional: true

  # Outputs
  output :record

  # Steps
  step :initialize_record
  step :assign_attributes
  step :authorize
  step :validate
  step :save_record

  private

  def initialize_record
    self.record = self.class.module_parent.new
  end

  def assign_attributes
    record.assign_attributes(filtered_params)
  end

  def authorize
    return if force || attributes

    # Here is some Pundit logic 👇
    authorize!(record, with_action: :create?)
  end

  def validate
    return if record.valid?

    errors.copy_from(record)
  end

  def save_record
    record.save_with!(self)
  end

  def filtered_params
    raise NotImplementedError
  end
end
```

**Now we can easily reuse all this code and create as many services as we want:**
```ruby
class Team::Create < CreateService
  alias team record
  
  private
  
  def filtered_params
    params.require(:team).permit(:name)
  end
end
```

## More examples

You can find more examples here:
[https://github.com/light-ruby/light-services/tree/spec/data/services](https://github.com/light-ruby/light-services/tree/v2/spec/data/services)

# Happy coding!

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

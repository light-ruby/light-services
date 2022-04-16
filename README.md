# 🚀 Light Services <sup>BETA</sup>

Implementation of Service Object pattern for Ruby/Rails applications.

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

1. Ability to define `arguments`, `steps` and `outputs`
2. Isolated behaviour of each service object
3. Raising of errors to stop processing next steps
4. Wrapping actions into database transactions
5. Ability to pass context to child service object
6. Framework agnostic
7. 100% test coverage

## ❌ Problems

As this gem was just for internal usage, it has some problems:

1. Gem isn't documented well
2. Code doesn't have any comments
3. Repo doesn't have any CI/CD

## Simple Example

### Send notification

Let's create an elementary service object that sends a notification to the user. 

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

You may send some arguments into the service object.

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

**How to pass arguments in controller:**
```ruby
class UsersController
  def send_notification
    service = User::SendNotification.run(user: User.first, provider: Provider.first)
    # ...
  end
end
```

**How to pass arguments and context from parent to child service object:**
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
      .with(self) # This line specifies the current service object as a parent and passes all context arguments into a child service object
      .run(text: "Your profile was updated") # We don't need to pass `user` here as it's a context argument
  end
end
```

### Steps

Steps are a bit more powerful than you think.

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

Outputs are pretty straightforward.

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

What context does:
1. It tells the parent service object to pass context arguments into a child service object
2. When the child service object fails, it tells the parent service object to fail too (customizable)

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

### Creation of records

Let's investigate a more exciting example where we create a wrapper to create database records.

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
[https://github.com/light-ruby/light-services/tree/v2/spec/data/services](https://github.com/light-ruby/light-services/tree/v2/spec/data/services)

# Happy coding!

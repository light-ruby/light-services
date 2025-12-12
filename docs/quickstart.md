# Quickstart

Light Services are framework-agnostic and can be used in any Ruby project.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "light-services", "~> 2.1"
```

Or you can install it yourself by running:

```bash
bundle add light-services --version "~> 2.1"
```

## Create `ApplicationService`

{% hint style="info" %}
This step is optional but recommended. Creating a base class for your services can help organize your code. This base class will act as the parent for all your services, where you can include common logic such as helpers, logging, error handling, etc.

P.S. I'm working on an installation script to automate this step.
{% endhint %}

First, create a folder for your services. The path will depend on the framework you are using. For Rails, you can create a folder in `app/services`.

```bash
mkdir app/services
```

Next, create your base class. You can name it as you wish, but we recommend `ApplicationService`.

```ruby
# app/services/application_service.rb
class ApplicationService < Light::Services::Base
  # Nothing to put here yet
end
```

## Create Your First Service

Now let's create our first service. We'll make a simple service that returns a greeting message.

```ruby
# app/services/greet_service.rb
class GreetService < ApplicationService
  # Arguments
  arg :name, type: String

  # Steps
  step :greet

  # Outputs
  output :greeted, default: false

  private

  def greet
    puts "Hello, #{name}!"
    self.greeted = true
  end
end
```

## Run the Service

Now you can run your service from anywhere in your application.

```ruby
service = GreetService.run(name: "John")
service.greeted # => true
```

### Check for Success or Failure

```ruby
service = GreetService.run(name: "John")

if service.success?
  puts "Greeting sent!"
  puts service.greeted
else
  puts "Failed: #{service.errors.to_h}"
end
```

### Raise on Error with `run!`

Use `run!` when you want errors to raise exceptions instead of being collected:

```ruby
# This will raise Light::Services::Error if any errors are added
service = GreetService.run!(name: "John")
```

This is equivalent to:

```ruby
service = GreetService.run({ name: "John" }, { raise_on_error: true })
```

{% hint style="info" %}
Looks easy, right? But this is just the beginning. Light Services can do much more 🚀
{% endhint %}

## What's Next?

Learn how to configure Light Services for your application:

[Next: Configuration](configuration.md)


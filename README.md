# Light::Services

[![Build Status](https://travis-ci.org/light-ruby/light-services.svg?branch=master)](https://travis-ci.org/light-ruby/light-services)
[![Code Climate](https://codeclimate.com/github/light-ruby/light-services/badges/gpa.svg)](https://codeclimate.com/github/light-ruby/light-services)
[![Test Coverage](https://api.codeclimate.com/v1/badges/ed8713a891f19318bd7c/test_coverage)](https://codeclimate.com/github/light-ruby/light-services/test_coverage)

Implementation of Service Object Pattern for Ruby/Rails. Compatible with Rails 5.1 and 5.0, 4.2, 4.1, 4.0.

Service Object Pattern – What is it? Check it here:
- [Wikipedia](https://en.wikipedia.org/wiki/Service_layer_pattern)
- [Essential RubyOnRails patterns — part 1: Service Objects](https://medium.com/selleo/essential-rubyonrails-patterns-part-1-service-objects-1af9f9573ca1)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'light-services', '~> 0.6' 
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install light-service

## Usage

#### Examples of usage:

**Change state of the record:**
```ruby
class Painting::Publish < ApplicationService
  # Parameters
  param :painting, type: Painting
  param :user,     type: User

  # Callbacks
  before :authorize
  after  :send_email_notification

  def run
    painting.publish!
  end

  private

  def authorize
    pundit_authorize!(painting, user, :publish?)
  end

  def send_email_notification
    PaintingMailer.publish_email(painting).deliver_now
  end
end
```

**Create a new record:**
```ruby
class Owner::Create < ApplicationService
  # Parameters
  param :params, type: ActionController::Parameters
  param :user,   type: User

  # Outputs
  output :owner

  # Callbacks
  before :assign_attributes
  before :authorize
  before :validate

  def run
    owner.save!
  end

  private

  def assign_attributes
    self.owner = Owner.new(owner_params)
  end

  def authorize
    pundit_authorize!(owner, user, :create?)
  end

  def validate
    return if owner.valid?
    errors.from_record(owner)
  end

  def owner_params
    params
      .require(:owner)
      .permit(:name)
  end
end
```

**Integration with Pundit:**
```ruby
class ApplicationService < Light::Services::Base
  def pundit_authorize!(record, user, action = nil)
    action = convert_action(action, :show?)
    policy = Pundit.policy!(user, record)

    return true if policy.public_send(action)

    Rails.logger.info "Pundit: not allowed to #{action} this #{record.inspect}"
    raise Pundit::NotAuthorizedError, query: action, policy: policy, record: record
  end

  def pundit_scope!(scope, user, action = nil)
    action = convert_action(action, :index?)
    pundit_authorize!(scope, user, action)

    Pundit.policy_scope!(user, scope)
  end
  
  private

  def convert_action(action, default)
    action = action.to_s

    return default if action.blank?
    return action if action.ends_with?('?')

    action + '?'
  end
end

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/light-service. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


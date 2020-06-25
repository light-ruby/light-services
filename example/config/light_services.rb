# frozen_string_literal: true

Light::Services.configure do |config|
  config.load_errors = true
  config.use_transactions = true
  config.rollback_on_error = true
  config.raise_on_error = false
end

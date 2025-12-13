# frozen_string_literal: true

class ApplicationService < Light::Services::Base
  # Disable require_type for test services to allow testing other features
  config require_type: false

  # Arguments
  arg :current_user, type: User, optional: true, context: true
end

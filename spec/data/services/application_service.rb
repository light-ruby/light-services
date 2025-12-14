# frozen_string_literal: true

class ApplicationService < Light::Services::Base
  # Disable require_arg_type and require_output_type for test services to allow testing other features
  config require_arg_type: false, require_output_type: false

  # Arguments
  arg :current_user, type: User, optional: true, context: true
end

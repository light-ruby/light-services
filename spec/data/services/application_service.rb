# frozen_string_literal: true

class ApplicationService < Light::Services::Base
  # Arguments
  arg :current_user, type: User, optional: true, context: true
end

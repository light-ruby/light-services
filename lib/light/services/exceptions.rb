# frozen_string_literal: true

module Light
  module Services
    class Error < StandardError; end
    class ParamRequired < Light::Services::Error; end
    class ParamType < Light::Services::Error; end
  end
end

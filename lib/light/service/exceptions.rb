module Light
  module Service
    class Error < StandardError; end
    class ParamRequired < Light::Service::Error; end
    class ParamType < Light::Service::Error; end
  end
end

# frozen_string_literal: true

# This class allows to run service object with context (parent class and custom config)
module Light
  module Services
    class BaseWithContext
      def initialize(service_class, parent_service, config)
        @service_class = service_class
        @config = config
        @parent_service = parent_service

        return if parent_service.nil? || parent_service.is_a?(Light::Services::Base)

        raise Light::Services::ArgTypeError, "#{parent_service.class} - must be a subclass of Light::Services::Base"
      end

      def run(args = {})
        @service_class.new(extend_arguments(args), @config, @parent_service).tap(&:run)
      end

      private

      def extend_arguments(args)
        return args unless @parent_service

        # TODO: Do we need `.dup` here?
        @parent_service.arguments.extend_with_context(args)
      end
    end
  end
end

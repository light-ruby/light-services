# frozen_string_literal: true

# This class allows running a service object with context (parent class and custom config)
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
        @service_class.new(extend_arguments(args), @config, @parent_service).tap(&:call)
      end

      def run!(args = {})
        @config[:raise_on_error] = true
        run(args)
      end

      private

      def extend_arguments(args)
        args = @parent_service.arguments.dup.extend_with_context(args) if @parent_service
        args[:deepness] += 1 if args[:deepness]

        args
      end
    end
  end
end

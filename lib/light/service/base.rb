module Light
  module Service
    class Base
      # Includes
      include Light::Service::Parameters
      include Light::Service::Callbacks

      # Getters
      attr_reader :params, :outputs, :errors, :warnings

      def initialize(args = {})
        @args = args

        @params   = initialize_params
        @outputs  = initialize_outputs
        @errors   = Light::Service::Messages.new
        @warnings = Light::Service::Messages.new
      end

      def self.call(args = {})
        service = new(args)
        service.call
        service
      end

      def call
        run_service
      end

      def success?
        errors.blank?
      end

      def any_warnings?
        !warnings.blank?
      end

      private

      # Getters
      attr_reader :args

      def run_service
        run_callbacks(:before)
        run if success?
        run_callbacks(:after) if success?
        run_callbacks(:finally)
        success?
      end
    end
  end
end

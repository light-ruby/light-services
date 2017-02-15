module Light
  module Services
    class Base
      # Includes
      include Light::Services::Parameters
      include Light::Services::Callbacks

      # Getters
      attr_reader :errors, :warnings

      def initialize(args = {})
        @args = args

        initialize_params
        initialize_outputs

        @errors   = Light::Services::Messages.new
        @warnings = Light::Services::Messages.new
      end

      def call
        run_service
      end

      def success?
        errors.blank?
      end

      def any_warnings?
        warnings.any?
      end

      class << self
        def call(args = {})
          service = new(args)
          service.call
          service
        end

        alias run call
      end

      private

      # Getters
      attr_reader :args

      def run_service
        run_callbacks(:before)
        run if success?
        run_callbacks(:after) if success?
        run_callbacks(:finally, break: false)
        success?
      end
    end
  end
end

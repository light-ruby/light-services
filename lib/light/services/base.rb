# frozen_string_literal: true

module Light
  module Services
    class Base
      # Includes
      include Light::Services::Parameters
      include Light::Services::Outputs
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
        within_transaction { run_service }
      end

      def success?
        errors.blank?
      end

      def any_warnings?
        warnings.any?
      end

      class << self
        def call(args = {})
          new(args).tap(&:call)
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
        run_callbacks(:finally, force_run: true)
        success?
      end

      def within_transaction
        if defined?(ActiveRecord::Base)
          ActiveRecord::Base.transaction do
            yield
          end
        else
          yield
        end
      end
    end
  end
end

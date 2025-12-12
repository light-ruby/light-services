# frozen_string_literal: true

require "light/services/constants"
require "light/services/message"
require "light/services/messages"
require "light/services/base_with_context"

require "light/services/settings/step"
require "light/services/settings/field"

require "light/services/collection"

require "light/services/dsl/arguments_dsl"
require "light/services/dsl/outputs_dsl"
require "light/services/dsl/steps_dsl"

require "light/services/concerns/execution"
require "light/services/concerns/state_management"
require "light/services/concerns/parent_service"

# Base class for all service objects
module Light
  module Services
    class Base
      include Callbacks
      include Dsl::ArgumentsDsl
      include Dsl::OutputsDsl
      include Dsl::StepsDsl
      include Concerns::Execution
      include Concerns::StateManagement
      include Concerns::ParentService

      # Getters
      attr_reader :outputs, :arguments, :errors, :warnings

      def initialize(args = {}, config = {}, parent_service = nil)
        @config = Light::Services.config.merge(self.class.class_config || {}).merge(config)
        @parent_service = parent_service

        @outputs = Collection::Base.new(self, CollectionTypes::OUTPUTS)
        @arguments = Collection::Base.new(self, CollectionTypes::ARGUMENTS, args.dup)

        @done = false
        @launched_steps = []

        initialize_errors
        initialize_warnings
      end

      def success?
        !errors?
      end

      def failed?
        errors?
      end

      def errors?
        @errors.any?
      end

      def warnings?
        @warnings.any?
      end

      def done!
        @done = true
      end

      def done?
        @done
      end

      def call
        load_defaults_and_validate

        run_callbacks(:before_service_run, self)

        run_callbacks(:around_service_run, self) do
          execute_service
        end

        run_service_result_callbacks
      rescue StandardError => e
        run_steps_with_always
        raise e
      end

      class << self
        attr_accessor :class_config

        def config(config = {})
          self.class_config = config
        end

        def run(args = {}, config = {})
          new(args, config).tap(&:call)
        end

        def run!(args = {}, config = {})
          run(args, config.merge(raise_on_error: true))
        end

        def with(service_or_config = {}, config = {})
          service = service_or_config.is_a?(Hash) ? nil : service_or_config
          config = service_or_config unless service

          BaseWithContext.new(self, service, config.dup)
        end
      end
    end
  end
end

# frozen_string_literal: true

require "light/services/step"
require "light/services/output"
require "light/services/argument"
require "light/services/collection"
require "light/services/class_based_collection"
require "light/services/mount_collection"

module Light
  module Services
    class Base
      # Includes
      extend MountCollection

      # Collections
      mount_collection :steps,     klass: Step,     singular: :step
      mount_collection :outputs,   klass: Output,   singular: :output
      mount_collection :arguments, klass: Argument, singular: :arg

      # Steps
      step :load_defaults_and_validate

      def initialize(args = {})
        @outputs = {}
        @arguments = args
      end

      def run
        self.class.steps.each do |step|
          step.run(self)
        end
      end

      class << self
        def run(args = {})
          new(args).tap(&:run)
        end
      end

      private

      def load_defaults_and_validate
        self.class.outputs.each do |output|
          next if !output.default_exists || @outputs.key?(output.name)

          @outputs[output.name] = output.default
        end

        self.class.arguments.each do |argument|
          if argument.default_exists && !@arguments.key?(argument.name)
            @arguments[argument.name] = argument.default
          end

          if !argument.optional || @arguments.key?(argument.name)
            argument.valid_type?(@arguments[argument.name])
          end
        end
      end
    end
  end
end

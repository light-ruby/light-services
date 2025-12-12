# frozen_string_literal: true

require "light/services/message"
require "light/services/messages"
require "light/services/base_with_context"

require "light/services/settings/step"
require "light/services/settings/field"

require "light/services/collection"

# Base class for all service objects
module Light
  module Services
    class Base
      include Callbacks

      # Getters
      attr_reader :outputs, :arguments, :errors, :warnings

      def initialize(args = {}, config = {}, parent_service = nil)
        @config = Light::Services.config.merge(self.class.class_config || {}).merge(config)
        @parent_service = parent_service

        @outputs = Collection::Base.new(self, :outputs)
        @arguments = Collection::Base.new(self, :arguments, args.dup)

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

        # ========== Arguments DSL ==========

        def arg(name, opts = {})
          own_arguments[name] = Settings::Field.new(name, self, opts.merge(field_type: :argument))
          @arguments = nil # Clear memoized arguments since we're modifying them
        end

        def remove_arg(name)
          own_arguments.delete(name)
          @arguments = nil # Clear memoized arguments since we're modifying them
        end

        def arguments
          @arguments ||= build_arguments
        end

        def own_arguments
          @own_arguments ||= {}
        end

        def build_arguments
          inherited = superclass.respond_to?(:arguments) ? superclass.arguments.dup : {}
          inherited.merge(own_arguments)
        end

        # ========== Steps DSL ==========

        def step(name, opts = {})
          validate_step_opts!(name, opts)

          # Build current steps to check for duplicates and find insertion targets
          current = steps
          raise Light::Services::Error, "Step `#{name}` already exists in service #{self}" if current.key?(name)

          if (target = opts[:before] || opts[:after]) && !current.key?(target)
            raise Light::Services::Error, "Cannot find step `#{target}` in service #{self}"
          end

          step_obj = Settings::Step.new(name, self, opts)

          if opts[:before] || opts[:after]
            step_operations << { action: :insert, name: name, step: step_obj, before: opts[:before],
                                 after: opts[:after], }
          else
            step_operations << { action: :add, name: name, step: step_obj }
          end

          # Clear memoized steps since we're modifying them
          @steps = nil
        end

        def remove_step(name)
          step_operations << { action: :remove, name: name }

          # Clear memoized steps since we're modifying them
          @steps = nil
        end

        def steps
          @steps ||= build_steps
        end

        def step_operations
          @step_operations ||= []
        end

        # ========== Outputs DSL ==========

        def output(name, opts = {})
          own_outputs[name] = Settings::Field.new(name, self, opts.merge(field_type: :output))
          # Clear memoized outputs since we're modifying them
          @outputs = nil
        end

        def remove_output(name)
          own_outputs.delete(name)
          # Clear memoized outputs since we're modifying them
          @outputs = nil
        end

        def outputs
          @outputs ||= build_outputs
        end

        def own_outputs
          @own_outputs ||= {}
        end

        def build_outputs
          inherited = superclass.respond_to?(:outputs) ? superclass.outputs.dup : {}
          inherited.merge(own_outputs)
        end

        private

        def validate_step_opts!(name, opts)
          return unless opts[:before] && opts[:after]

          raise Light::Services::Error, "You cannot specify `before` and `after` " \
                                        "for step `#{name}` in service #{self} at the same time"
        end

        def build_steps
          # Start with inherited steps
          result = inherit_steps

          # Apply operations in order
          step_operations.each { |op| apply_step_operation(result, op) }

          result
        end

        def inherit_steps
          superclass.respond_to?(:steps) ? superclass.steps.dup : {}
        end

        def apply_step_operation(steps, operation)
          case operation[:action]
          when :add
            steps[operation[:name]] = operation[:step]
          when :remove
            steps.delete(operation[:name])
          when :insert
            insert_step(steps, operation)
          end
        end

        def insert_step(steps, operation)
          target = operation[:before] || operation[:after]
          keys = steps.keys
          index = keys.index(target)
          return unless index

          # More efficient insertion using ordered hash reconstruction
          new_steps = {}
          keys.each_with_index do |key, i|
            # Insert before target
            new_steps[operation[:name]] = operation[:step] if operation[:before] && i == index
            new_steps[key] = steps[key]
            # Insert after target
            new_steps[operation[:name]] = operation[:step] if operation[:after] && i == index
          end
          steps.replace(new_steps)
        end
      end

      private

      def execute_service
        run_steps
        run_steps_with_always
        @outputs.validate! if success?

        copy_warnings_to_parent_service
        copy_errors_to_parent_service
      end

      def run_service_result_callbacks
        run_callbacks(:after_service_run, self)

        if success?
          run_callbacks(:on_service_success, self)
        else
          run_callbacks(:on_service_failure, self)
        end
      end

      def initialize_errors
        @errors = Messages.new(
          break_on_add: @config[:break_on_error],
          raise_on_add: @config[:raise_on_error],
          rollback_on_add: @config[:use_transactions] && @config[:rollback_on_error],
        )
      end

      def initialize_warnings
        @warnings = Messages.new(
          break_on_add: @config[:break_on_warning],
          raise_on_add: @config[:raise_on_warning],
          rollback_on_add: @config[:use_transactions] && @config[:rollback_on_warning],
        )
      end

      def run_steps
        within_transaction do
          # Cache steps once for both normal and always execution
          @cached_steps = self.class.steps

          @cached_steps.each do |name, step|
            @launched_steps << name if step.run(self)

            break if @errors.break? || @warnings.break?
          end
        end
      end

      # Run steps with parameter `always` if they weren't launched because of errors/warnings
      def run_steps_with_always
        # Use cached steps from run_steps, or get them if run_steps wasn't called
        steps_to_check = @cached_steps || self.class.steps

        steps_to_check.each do |name, step|
          next if !step.always || @launched_steps.include?(name)

          @launched_steps << name if step.run(self)
        end
      end

      def copy_warnings_to_parent_service
        return if !@parent_service || !@config[:load_warnings]

        @parent_service.warnings.copy_from(
          @warnings,
          break: @config[:self_break_on_warning],
          rollback: @config[:self_rollback_on_warning],
        )
      end

      def copy_errors_to_parent_service
        return if !@parent_service || !@config[:load_errors]

        @parent_service.errors.copy_from(
          @errors,
          break: @config[:self_break_on_error],
          rollback: @config[:self_rollback_on_error],
        )
      end

      def load_defaults_and_validate
        @outputs.load_defaults
        @arguments.load_defaults
        @arguments.validate!
      end

      def within_transaction(&block)
        if @config[:use_transactions] && defined?(ActiveRecord::Base)
          ActiveRecord::Base.transaction(requires_new: true, &block)
        else
          yield
        end
      end
    end
  end
end

# frozen_string_literal: true

# This class defines settings for step
module Light
  module Services
    module Settings
      class Step
        # Getters
        attr_reader :name, :always

        def initialize(name, service_class, opts = {})
          @name = name
          @service_class = service_class

          @if     = opts[:if]
          @unless = opts[:unless]
          @always = opts[:always]

          if @if && @unless
            raise Light::Services::Error, "#{service_class} `if` and `unless` cannot be specified " \
                                          "for the step `#{name}` at the same time"
          end
        end

        def run(instance) # rubocop:disable Naming/PredicateMethod
          return false unless run?(instance)

          unless instance.respond_to?(name, true)
            available_steps = @service_class.steps.keys.join(", ")
            raise Light::Services::Error,
                  "Step method `#{name}` is not defined in #{@service_class}. " \
                  "Defined steps: [#{available_steps}]"
          end

          execute_with_callbacks(instance)
          true
        end

        private

        def execute_with_callbacks(instance)
          errors_count_before = instance.errors.count

          instance.run_callbacks(:before_step_run, instance, name)

          instance.run_callbacks(:around_step_run, instance, name) do
            instance.send(name)
          end

          instance.run_callbacks(:after_step_run, instance, name)

          if instance.errors.count > errors_count_before
            instance.run_callbacks(:on_step_failure, instance, name)
          else
            instance.run_callbacks(:on_step_success, instance, name)
          end
        rescue StandardError => e
          instance.run_callbacks(:on_step_crash, instance, name, e)
          raise e
        end

        def run?(instance)
          return false if instance.stopped?

          if @if
            check_condition(@if, instance)
          elsif @unless
            !check_condition(@unless, instance)
          else
            true
          end
        end

        def check_condition(condition, instance)
          case condition
          when Symbol
            instance.send(condition)
          when Proc
            instance.instance_exec(&condition)
          else
            raise Light::Services::Error, "#{@service_class} condition should be a Symbol or Proc " \
                                          "for the step `#{@name}` (currently: #{condition.class})"
          end
        end
      end
    end
  end
end

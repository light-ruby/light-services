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
            raise Light::Services::TwoConditions, "#{service_class} `if` and `unless` cannot be specified " \
                                                  "for the step `#{name}` at the same time"
          end
        end

        def run(instance, benchmark: false)
          return false unless run?(instance)

          if instance.respond_to?(name, true)
            if benchmark
              time = Benchmark.ms do
                instance.send(name)
              end

              instance.log "⏱️ Step #{name} took #{time}ms"
            else
              instance.send(name)
            end

            true
          else
            raise Light::Services::NoStepError, "Cannot find step `#{name}` in service `#{@service_class}`"
          end
        end

        private

        def run?(instance)
          return false if instance.done?

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

# frozen_string_literal: true

module Light
  module Services
    module Settings
      class Step
        # Getters
        attr_reader :name, :always

        def initialize(name, klass, opts = {})
          @name = name
          @klass = klass

          @if     = opts[:if]
          @unless = opts[:unless]
          @always = opts[:always]

          if @if && @unless
            raise Light::Services::TwoConditions, "#{klass}##{name} - `if` and `unless` cannot be specified together"
          end
        end

        def run(instance)
          return false unless run?(instance)

          if instance.respond_to?(name, true)
            instance.send(name)
            true
          else
            raise Light::Services::NoStepError, "Cannot find step `#{name}` in service `#{instance.class}`"
          end
        end

        private

        def run?(instance)
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
            instance.public_send(condition)
          when Proc
            condition.call
          else
            raise Light::Services::Error, "#{@klass}##{@name} - condition should be a Symbol or Proc (currently: #{condition.class})"
          end
        end
      end
    end
  end
end

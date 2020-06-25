# frozen_string_literal: true

module Light
  module Services
    class Step
      # Getters
      attr_reader :name

      def initialize(name, klass, opts = {})
        @name = name
        @klass = klass

        @if     = opts[:if]
        @unless = opts[:unless]
        @always = opts[:always]

        if @if && @unless
          # TODO: Update error
          raise Light::Services::Error
        end
      end

      def run(instance)
        return unless run?(instance)

        if instance.respond_to?(name, true)
          instance.send(name)
        else
          # TODO: Update error
          raise Light::Services::Error, "`#{instance.class}` step `#{name}` not found"
        end
      end

      private

      def run?(instance)
        if @if
          check_condition(@if, instance)
        elsif @else
          check_condition(@else, instance)
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
          # TODO: Update error
          raise Light::Services::Error
        end
      end
    end
  end
end

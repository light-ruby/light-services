# frozen_string_literal: true

module Operandi
  module RSpec
    module Matchers
      # Matcher for testing step definitions on a service class
      #
      # @example Basic usage
      #   expect(MyService).to define_step(:validate)
      #
      # @example With always flag
      #   expect(MyService).to define_step(:cleanup).with_always(true)
      #
      # @example With if condition
      #   expect(MyService).to define_step(:notify).with_if(:should_notify?)
      #
      # @example With unless condition
      #   expect(MyService).to define_step(:skip_validation).with_unless(:production?)
      #
      # @example Check multiple steps
      #   expect(MyService).to define_steps(:validate, :process, :save)
      #
      # @example Check step order
      #   expect(MyService).to define_steps_in_order(:validate, :process, :save)
      def define_step(name)
        DefineStepMatcher.new(name)
      end

      def define_steps(*names)
        DefineStepsMatcher.new(names, ordered: false)
      end

      def define_steps_in_order(*names)
        DefineStepsMatcher.new(names, ordered: true)
      end

      class DefineStepMatcher
        def initialize(name)
          @name = name
          @expected_always = nil
          @expected_if = nil
          @expected_unless = nil
        end

        def with_always(value = true)
          @expected_always = value
          self
        end

        def with_if(condition)
          @expected_if = condition
          self
        end

        def with_unless(condition)
          @expected_unless = condition
          self
        end

        def matches?(service_class)
          @service_class = service_class
          @actual_class = service_class.is_a?(Class) ? service_class : service_class.class

          return false unless step_defined?
          return false unless always_matches?
          return false unless if_matches?
          return false unless unless_matches?

          true
        end

        def failure_message
          return "expected #{@actual_class} to define step :#{@name}" unless step_defined?
          return always_failure_message unless always_matches?
          return if_failure_message unless if_matches?
          return unless_failure_message unless unless_matches?

          ""
        end

        def failure_message_when_negated
          "expected #{@actual_class} not to define step :#{@name}"
        end

        def description
          desc = "define step :#{@name}"
          desc += " with always: #{@expected_always}" unless @expected_always.nil?
          desc += " with if: #{@expected_if.inspect}" if @expected_if
          desc += " with unless: #{@expected_unless.inspect}" if @expected_unless
          desc
        end

        private

        def step_defined?
          @actual_class.respond_to?(:steps) && @actual_class.steps.key?(@name)
        end

        def step
          @step ||= @actual_class.steps[@name]
        end

        def always_matches?
          return true if @expected_always.nil?

          step.always == @expected_always
        end

        def if_matches?
          return true if @expected_if.nil?

          actual_if = step.instance_variable_get(:@if)
          actual_if == @expected_if
        end

        def unless_matches?
          return true if @expected_unless.nil?

          actual_unless = step.instance_variable_get(:@unless)
          actual_unless == @expected_unless
        end

        def always_failure_message
          "expected #{@actual_class} step :#{@name} to have always: #{@expected_always}, " \
            "but it has always: #{step.always.inspect}"
        end

        def if_failure_message
          actual_if = step.instance_variable_get(:@if)
          "expected #{@actual_class} step :#{@name} to have if: #{@expected_if.inspect}, " \
            "but it has if: #{actual_if.inspect}"
        end

        def unless_failure_message
          actual_unless = step.instance_variable_get(:@unless)
          "expected #{@actual_class} step :#{@name} to have unless: #{@expected_unless.inspect}, " \
            "but it has unless: #{actual_unless.inspect}"
        end
      end

      class DefineStepsMatcher
        def initialize(names, ordered:)
          @names = names
          @ordered = ordered
        end

        def matches?(service_class)
          @service_class = service_class
          @actual_class = service_class.is_a?(Class) ? service_class : service_class.class
          @missing_steps = []
          @actual_order = []

          return false unless all_steps_defined?
          return false unless order_matches?

          true
        end

        def failure_message
          return missing_steps_failure_message unless all_steps_defined?
          return order_failure_message unless order_matches?

          ""
        end

        def failure_message_when_negated
          if @ordered
            "expected #{@actual_class} not to define steps #{@names.inspect} in that order"
          else
            "expected #{@actual_class} not to define steps #{@names.inspect}"
          end
        end

        def description
          if @ordered
            "define steps #{@names.inspect} in order"
          else
            "define steps #{@names.inspect}"
          end
        end

        private

        def all_steps_defined?
          return false unless @actual_class.respond_to?(:steps)

          actual_step_names = @actual_class.steps.keys
          @missing_steps = @names - actual_step_names
          @missing_steps.empty?
        end

        def order_matches?
          return true unless @ordered

          actual_step_names = @actual_class.steps.keys
          @actual_order = @names.select { |name| actual_step_names.include?(name) }

          # Check if the expected steps appear in the same order in actual steps
          last_index = -1
          @names.all? do |name|
            current_index = actual_step_names.index(name)
            return false unless current_index
            return false unless current_index > last_index

            last_index = current_index
            true
          end
        end

        def missing_steps_failure_message
          "expected #{@actual_class} to define steps #{@names.inspect}, " \
            "but missing: #{@missing_steps.inspect}"
        end

        def order_failure_message
          actual_step_names = @actual_class.steps.keys
          "expected #{@actual_class} to define steps #{@names.inspect} in that order, " \
            "but actual order is: #{actual_step_names.inspect}"
        end
      end
    end
  end
end

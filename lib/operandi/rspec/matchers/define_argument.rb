# frozen_string_literal: true

module Operandi
  module RSpec
    module Matchers
      # Matcher for testing argument definitions on a service class
      #
      # @example Basic usage
      #   expect(MyService).to define_argument(:name)
      #
      # @example With type constraint
      #   expect(MyService).to define_argument(:name).with_type(String)
      #
      # @example With optional flag
      #   expect(MyService).to define_argument(:email).optional
      #
      # @example With default value
      #   expect(MyService).to define_argument(:status).with_default("pending")
      #
      # @example With context flag
      #   expect(MyService).to define_argument(:current_user).with_context
      #
      # @example Combined
      #   expect(MyService).to define_argument(:count).with_type(Integer).optional.with_default(0)
      def define_argument(name)
        DefineArgumentMatcher.new(name)
      end

      class DefineArgumentMatcher
        def initialize(name)
          @name = name
          @expected_type = nil
          @expected_optional = nil
          @expected_default = nil
          @check_default = false
          @expected_context = nil
        end

        def with_type(type)
          @expected_type = type
          self
        end

        def optional(value = true)
          @expected_optional = value
          self
        end

        def required
          @expected_optional = false
          self
        end

        def with_default(default)
          @check_default = true
          @expected_default = default
          self
        end

        def with_context(value = true)
          @expected_context = value
          self
        end

        def matches?(service_class)
          @service_class = service_class
          @actual_class = service_class.is_a?(Class) ? service_class : service_class.class

          return false unless argument_defined?
          return false unless type_matches?
          return false unless optional_matches?
          return false unless default_matches?
          return false unless context_matches?

          true
        end

        def failure_message
          return "expected #{@actual_class} to define argument :#{@name}" unless argument_defined?
          return type_failure_message unless type_matches?
          return optional_failure_message unless optional_matches?
          return default_failure_message unless default_matches?
          return context_failure_message unless context_matches?

          ""
        end

        def failure_message_when_negated
          "expected #{@actual_class} not to define argument :#{@name}"
        end

        def description
          desc = "define argument :#{@name}"
          desc += " with type #{@expected_type}" if @expected_type
          desc += " as optional" if @expected_optional == true
          desc += " as required" if @expected_optional == false
          desc += " with default #{@expected_default.inspect}" if @check_default
          desc += " with context" if @expected_context
          desc
        end

        private

        def argument_defined?
          @actual_class.respond_to?(:arguments) && @actual_class.arguments.key?(@name)
        end

        def argument
          @argument ||= @actual_class.arguments[@name]
        end

        def type_matches?
          return true if @expected_type.nil?

          # Access the type via instance variable since there's no public getter
          actual_type = argument.instance_variable_get(:@type)
          actual_type == @expected_type
        end

        def optional_matches?
          return true if @expected_optional.nil?

          argument.optional == @expected_optional
        end

        def default_matches?
          return true unless @check_default

          argument.default_exists && argument.default == @expected_default
        end

        def context_matches?
          return true if @expected_context.nil?

          argument.context == @expected_context
        end

        def type_failure_message
          actual_type = argument.instance_variable_get(:@type)
          "expected #{@actual_class} argument :#{@name} to have type #{@expected_type}, " \
            "but it has type #{actual_type.inspect}"
        end

        def optional_failure_message
          if @expected_optional
            "expected #{@actual_class} argument :#{@name} to be optional, but it is required"
          else
            "expected #{@actual_class} argument :#{@name} to be required, but it is optional"
          end
        end

        def default_failure_message
          if argument.default_exists
            "expected #{@actual_class} argument :#{@name} to have default #{@expected_default.inspect}, " \
              "but it has default #{argument.default.inspect}"
          else
            "expected #{@actual_class} argument :#{@name} to have default #{@expected_default.inspect}, " \
              "but no default is defined"
          end
        end

        def context_failure_message
          if @expected_context
            "expected #{@actual_class} argument :#{@name} to have context flag, but it doesn't"
          else
            "expected #{@actual_class} argument :#{@name} not to have context flag, but it does"
          end
        end
      end
    end
  end
end

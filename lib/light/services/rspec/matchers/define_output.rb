# frozen_string_literal: true

module Light
  module Services
    module RSpec
      module Matchers
        # Matcher for testing output definitions on a service class
        #
        # @example Basic usage
        #   expect(MyService).to define_output(:result)
        #
        # @example With type constraint
        #   expect(MyService).to define_output(:product).with_type(Product)
        #
        # @example With optional flag
        #   expect(MyService).to define_output(:message).optional
        #
        # @example With default value
        #   expect(MyService).to define_output(:count).with_default(0)
        #
        # @example Combined
        #   expect(MyService).to define_output(:data).with_type(Hash).optional.with_default({})
        def define_output(name)
          DefineOutputMatcher.new(name)
        end

        class DefineOutputMatcher
          def initialize(name)
            @name = name
            @expected_type = nil
            @expected_optional = nil
            @expected_default = nil
            @check_default = false
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

          def matches?(service_class)
            @service_class = service_class
            @actual_class = service_class.is_a?(Class) ? service_class : service_class.class

            return false unless output_defined?
            return false unless type_matches?
            return false unless optional_matches?
            return false unless default_matches?

            true
          end

          def failure_message
            return "expected #{@actual_class} to define output :#{@name}" unless output_defined?
            return type_failure_message unless type_matches?
            return optional_failure_message unless optional_matches?
            return default_failure_message unless default_matches?

            ""
          end

          def failure_message_when_negated
            "expected #{@actual_class} not to define output :#{@name}"
          end

          def description
            desc = "define output :#{@name}"
            desc += " with type #{@expected_type}" if @expected_type
            desc += " as optional" if @expected_optional == true
            desc += " as required" if @expected_optional == false
            desc += " with default #{@expected_default.inspect}" if @check_default
            desc
          end

          private

          def output_defined?
            @actual_class.respond_to?(:outputs) && @actual_class.outputs.key?(@name)
          end

          def output
            @output ||= @actual_class.outputs[@name]
          end

          def type_matches?
            return true if @expected_type.nil?

            actual_type = output.instance_variable_get(:@type)
            actual_type == @expected_type
          end

          def optional_matches?
            return true if @expected_optional.nil?

            output.optional == @expected_optional
          end

          def default_matches?
            return true unless @check_default

            output.default_exists && output.default == @expected_default
          end

          def type_failure_message
            actual_type = output.instance_variable_get(:@type)
            "expected #{@actual_class} output :#{@name} to have type #{@expected_type}, " \
              "but it has type #{actual_type.inspect}"
          end

          def optional_failure_message
            if @expected_optional
              "expected #{@actual_class} output :#{@name} to be optional, but it is required"
            else
              "expected #{@actual_class} output :#{@name} to be required, but it is optional"
            end
          end

          def default_failure_message
            if output.default_exists
              "expected #{@actual_class} output :#{@name} to have default #{@expected_default.inspect}, " \
                "but it has default #{output.default.inspect}"
            else
              "expected #{@actual_class} output :#{@name} to have default #{@expected_default.inspect}, " \
                "but no default is defined"
            end
          end
        end
      end
    end
  end
end

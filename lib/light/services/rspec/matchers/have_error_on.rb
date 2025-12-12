# frozen_string_literal: true

module Light
  module Services
    module RSpec
      module Matchers
        # Matcher for testing errors on a service instance
        #
        # @example Basic usage
        #   expect(service).to have_error_on(:name)
        #
        # @example With specific message
        #   expect(service).to have_error_on(:name).with_message("can't be blank")
        #
        # @example With message matching regex
        #   expect(service).to have_error_on(:base).with_message(/invalid/)
        #
        # @example Check multiple error keys
        #   expect(service).to have_errors_on(:name, :email)
        def have_error_on(key)
          HaveErrorOnMatcher.new(key)
        end

        def have_errors_on(*keys)
          HaveErrorsOnMatcher.new(keys)
        end

        class HaveErrorOnMatcher
          def initialize(key)
            @key = key
            @expected_message = nil
          end

          def with_message(message)
            @expected_message = message
            self
          end

          def matches?(service)
            @service = service

            return false unless has_error_key?
            return false unless message_matches?

            true
          end

          def failure_message
            unless has_error_key?
              return "expected service to have error on :#{@key}, but errors were: #{errors_summary}"
            end
            return message_failure_message unless message_matches?

            ""
          end

          def failure_message_when_negated
            if @expected_message
              "expected service not to have error on :#{@key} with message #{@expected_message.inspect}"
            else
              "expected service not to have error on :#{@key}"
            end
          end

          def description
            desc = "have error on :#{@key}"
            desc += " with message #{@expected_message.inspect}" if @expected_message
            desc
          end

          private

          def has_error_key?
            @service.errors.key?(@key)
          end

          def message_matches?
            return true if @expected_message.nil?

            error_messages = @service.errors[@key].map(&:to_s)

            case @expected_message
            when Regexp
              error_messages.any? { |msg| msg.match?(@expected_message) }
            else
              error_messages.include?(@expected_message.to_s)
            end
          end

          def message_failure_message
            actual_messages = @service.errors[@key].map(&:to_s)
            "expected service error on :#{@key} to include message #{@expected_message.inspect}, " \
              "but messages were: #{actual_messages.inspect}"
          end

          def errors_summary
            if @service.errors.empty?
              "empty"
            else
              @service.errors.to_h.inspect
            end
          end
        end

        class HaveErrorsOnMatcher
          def initialize(keys)
            @keys = keys
          end

          def matches?(service)
            @service = service
            @missing_keys = []

            @keys.each do |key|
              @missing_keys << key unless @service.errors.key?(key)
            end

            @missing_keys.empty?
          end

          def failure_message
            "expected service to have errors on #{@keys.inspect}, " \
              "but missing errors on: #{@missing_keys.inspect}. " \
              "Actual errors: #{errors_summary}"
          end

          def failure_message_when_negated
            "expected service not to have errors on #{@keys.inspect}"
          end

          def description
            "have errors on #{@keys.inspect}"
          end

          private

          def errors_summary
            if @service.errors.empty?
              "empty"
            else
              @service.errors.to_h.inspect
            end
          end
        end
      end
    end
  end
end

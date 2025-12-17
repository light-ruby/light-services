# frozen_string_literal: true

module Operandi
  module RSpec
    module Matchers
      # Matcher for testing warnings on a service instance
      #
      # @example Basic usage
      #   expect(service).to have_warning_on(:name)
      #
      # @example With specific message
      #   expect(service).to have_warning_on(:name).with_message("was replaced")
      #
      # @example With message matching regex
      #   expect(service).to have_warning_on(:base).with_message(/deprecated/)
      #
      # @example Check multiple warning keys
      #   expect(service).to have_warnings_on(:name, :email)
      def have_warning_on(key)
        HaveWarningOnMatcher.new(key)
      end

      def have_warnings_on(*keys)
        HaveWarningsOnMatcher.new(keys)
      end

      class HaveWarningOnMatcher
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

          return false unless has_warning_key?
          return false unless message_matches?

          true
        end

        def failure_message
          unless has_warning_key?
            return "expected service to have warning on :#{@key}, but warnings were: #{warnings_summary}"
          end
          return message_failure_message unless message_matches?

          ""
        end

        def failure_message_when_negated
          if @expected_message
            "expected service not to have warning on :#{@key} with message #{@expected_message.inspect}"
          else
            "expected service not to have warning on :#{@key}"
          end
        end

        def description
          desc = "have warning on :#{@key}"
          desc += " with message #{@expected_message.inspect}" if @expected_message
          desc
        end

        private

        def has_warning_key?
          @service.warnings.key?(@key)
        end

        def message_matches?
          return true if @expected_message.nil?

          warning_messages = @service.warnings[@key].map(&:to_s)

          case @expected_message
          when Regexp
            warning_messages.any? { |msg| msg.match?(@expected_message) }
          else
            warning_messages.include?(@expected_message.to_s)
          end
        end

        def message_failure_message
          actual_messages = @service.warnings[@key].map(&:to_s)
          "expected service warning on :#{@key} to include message #{@expected_message.inspect}, " \
            "but messages were: #{actual_messages.inspect}"
        end

        def warnings_summary
          if @service.warnings.empty?
            "empty"
          else
            @service.warnings.to_h.inspect
          end
        end
      end

      class HaveWarningsOnMatcher
        def initialize(keys)
          @keys = keys
        end

        def matches?(service)
          @service = service
          @missing_keys = []

          @keys.each do |key|
            @missing_keys << key unless @service.warnings.key?(key)
          end

          @missing_keys.empty?
        end

        def failure_message
          "expected service to have warnings on #{@keys.inspect}, " \
            "but missing warnings on: #{@missing_keys.inspect}. " \
            "Actual warnings: #{warnings_summary}"
        end

        def failure_message_when_negated
          "expected service not to have warnings on #{@keys.inspect}"
        end

        def description
          "have warnings on #{@keys.inspect}"
        end

        private

        def warnings_summary
          if @service.warnings.empty?
            "empty"
          else
            @service.warnings.to_h.inspect
          end
        end
      end
    end
  end
end

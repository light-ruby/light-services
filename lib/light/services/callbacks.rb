# frozen_string_literal: true

module Light
  module Services
    # Provides callback hooks for service and step lifecycle events.
    #
    # @example Service-level callbacks
    #   class MyService < Light::Services::Base
    #     before_service_run :log_start
    #     after_service_run { |service| Rails.logger.info("Done!") }
    #     on_service_success :send_notification
    #     on_service_failure :log_error
    #   end
    #
    # @example Step-level callbacks
    #   class MyService < Light::Services::Base
    #     before_step_run :log_step_start
    #     after_step_run { |service, step_name| puts "Finished #{step_name}" }
    #     on_step_failure :handle_step_error
    #   end
    #
    # @example Around callbacks
    #   class MyService < Light::Services::Base
    #     around_service_run :with_timing
    #
    #     private
    #
    #     def with_timing(service)
    #       start = Time.now
    #       yield
    #       puts "Took #{Time.now - start}s"
    #     end
    #   end
    module Callbacks
      # Available callback events.
      # @return [Array<Symbol>] list of callback event names
      EVENTS = [
        :before_step_run,
        :after_step_run,
        :around_step_run,
        :on_step_success,
        :on_step_failure,
        :on_step_crash,
        :before_service_run,
        :after_service_run,
        :around_service_run,
        :on_service_success,
        :on_service_failure,
      ].freeze

      def self.included(base)
        base.extend(ClassMethods)
      end

      # Class methods for registering callbacks.
      #
      # Each callback event has a corresponding class method:
      # - {before_step_run} - before each step executes
      # - {after_step_run} - after each step executes
      # - {around_step_run} - wraps step execution (must yield)
      # - {on_step_success} - when a step completes without adding errors
      # - {on_step_failure} - when a step adds errors
      # - {on_step_crash} - when a step raises an exception
      # - {before_service_run} - before the service starts
      # - {after_service_run} - after the service completes
      # - {around_service_run} - wraps service execution (must yield)
      # - {on_service_success} - when service completes without errors
      # - {on_service_failure} - when service completes with errors
      module ClassMethods
        # Define DSL methods for each callback event
        EVENTS.each do |event|
          define_method(event) do |method_name = nil, &block|
            callback = method_name || block
            raise ArgumentError, "#{event} requires a method name (symbol) or a block" unless callback

            unless callback.is_a?(Symbol) || callback.is_a?(Proc)
              raise ArgumentError,
                    "#{event} callback must be a Symbol or Proc"
            end

            callbacks_for(event) << callback
          end
        end

        # Get callbacks defined in this class for a specific event.
        #
        # @param event [Symbol] the callback event name
        # @return [Array<Symbol, Proc>] callbacks for this event
        def callbacks_for(event)
          @callbacks ||= {}
          @callbacks[event] ||= []
        end

        # Get all callbacks for an event including inherited ones.
        #
        # @param event [Symbol] the callback event name
        # @return [Array<Symbol, Proc>] all callbacks for this event
        def all_callbacks_for(event)
          if superclass.respond_to?(:all_callbacks_for)
            inherited = superclass.all_callbacks_for(event)
          else
            inherited = []
          end

          inherited + callbacks_for(event)
        end
      end

      # Run all callbacks for a given event.
      #
      # @param event [Symbol] the callback event name
      # @param args [Array] arguments to pass to callbacks
      # @yield for around callbacks, the block to wrap
      # @return [void]
      def run_callbacks(event, *args, &block)
        callbacks = self.class.all_callbacks_for(event)

        if event.to_s.start_with?("around_")
          run_around_callbacks(callbacks, args, &block)
        else
          run_simple_callbacks(callbacks, args)
          yield if block_given?
        end
      end

      private

      def run_simple_callbacks(callbacks, args)
        callbacks.each do |callback|
          execute_callback(callback, args)
        end
      end

      def run_around_callbacks(callbacks, args, &block)
        return yield if callbacks.empty?

        # Build a chain of around callbacks
        chain = callbacks.reverse.reduce(block) do |next_block, callback|
          proc { execute_callback(callback, args, &next_block) }
        end

        chain.call
      end

      def execute_callback(callback, args, &block)
        case callback
        in Symbol
          block_given? ? send(callback, *args, &block) : send(callback, *args)
        in Proc
          block_given? ? instance_exec(*args, block, &callback) : instance_exec(*args, &callback)
        else
          raise ArgumentError, "Callback must be a Symbol or Proc, got #{callback.class}"
        end
      end
    end
  end
end

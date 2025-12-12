# frozen_string_literal: true

module Light
  module Services
    module Callbacks
      # All supported callback events
      EVENTS = [
        :before_step_run,
        :after_step_run,
        :around_step_run,
        :on_step_success,
        :on_step_failure,
        :before_service_run,
        :after_service_run,
        :around_service_run,
        :on_service_success,
        :on_service_failure,
      ].freeze

      STEP_EVENTS = [
        :before_step_run,
        :after_step_run,
        :around_step_run,
        :on_step_success,
        :on_step_failure,
      ].freeze

      SERVICE_EVENTS = [
        :before_service_run,
        :after_service_run,
        :around_service_run,
        :on_service_success,
        :on_service_failure,
      ].freeze

      def self.included(base)
        base.extend(ClassMethods)
      end

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

        # Get all callbacks for a specific event (including inherited ones)
        def callbacks_for(event)
          @callbacks ||= {}
          @callbacks[event] ||= []
        end

        # Get all callbacks including inherited ones
        def all_callbacks_for(event)
          if superclass.respond_to?(:all_callbacks_for)
            inherited = superclass.all_callbacks_for(event)
          else
            inherited = []
          end

          inherited + callbacks_for(event)
        end
      end

      # Run callbacks for a given event
      # For around callbacks, yields to the block
      # For other callbacks, just executes them in order
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
        when Symbol
          if block_given?
            send(callback, *args, &block)
          else
            send(callback, *args)
          end
        when Proc
          if block_given?
            instance_exec(*args, block, &callback)
          else
            instance_exec(*args, &callback)
          end
        else
          raise ArgumentError, "Callback must be a Symbol or Proc, got #{callback.class}"
        end
      end
    end
  end
end

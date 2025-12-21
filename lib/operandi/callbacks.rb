# frozen_string_literal: true

module Operandi
  # Provides callback hooks for service and step lifecycle events.
  #
  # @example Service-level callbacks
  #   class MyService < Operandi::Base
  #     before_service_run :log_start
  #     after_service_run { |service| Rails.logger.info("Done!") }
  #     on_service_success :send_notification
  #     on_service_failure :log_error
  #   end
  #
  # @example Step-level callbacks
  #   class MyService < Operandi::Base
  #     before_step_run :log_step_start
  #     after_step_run { |service, step_name| puts "Finished #{step_name}" }
  #     on_step_failure :handle_step_error
  #   end
  #
  # @example Around callbacks
  #   class MyService < Operandi::Base
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

    # Run all callbacks for a given event.
    #
    # @param event [Symbol] the callback event name
    # @param args [Array] arguments to pass to callbacks
    # @yield for around callbacks, the block to wrap
    # @return [void]
    def run_callbacks(event, *args, &)
      callbacks = self.class.all_callbacks_for(event)

      if event.to_s.start_with?("around_")
        run_around_callbacks(callbacks, args, &)
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

  # Class methods for registering callbacks.
  # Extend this module in your service class to get callback DSL methods.
  #
  # @example
  #   class MyService < Operandi::Base
  #     before_service_run :setup
  #     after_service_run :cleanup
  #   end
  module CallbackDsl
    # Registers a callback to run before each step executes.
    #
    # @param method_name [Symbol, nil] name of the instance method to call
    # @yield [service, step_name] block to execute if no method name provided
    # @yieldparam service [Operandi::Base] the service instance
    # @yieldparam step_name [Symbol] the name of the step about to run
    # @return [void]
    # @raise [ArgumentError] if neither method name nor block is provided
    #
    # @example With method name
    #   before_step_run :log_step_start
    #
    # @example With block
    #   before_step_run { |service, step_name| puts "Starting #{step_name}" }
    def before_step_run(method_name = nil, &)
      register_callback(:before_step_run, method_name, &)
    end

    # Registers a callback to run after each step executes.
    #
    # @param method_name [Symbol, nil] name of the instance method to call
    # @yield [service, step_name] block to execute if no method name provided
    # @yieldparam service [Operandi::Base] the service instance
    # @yieldparam step_name [Symbol] the name of the step that just ran
    # @return [void]
    # @raise [ArgumentError] if neither method name nor block is provided
    #
    # @example With method name
    #   after_step_run :log_step_complete
    #
    # @example With block
    #   after_step_run { |service, step_name| puts "Finished #{step_name}" }
    def after_step_run(method_name = nil, &)
      register_callback(:after_step_run, method_name, &)
    end

    # Registers an around callback that wraps each step execution.
    # The callback must yield to execute the step.
    #
    # @param method_name [Symbol, nil] name of the instance method to call
    # @yield [service, step_name] block to execute if no method name provided
    # @yieldparam service [Operandi::Base] the service instance
    # @yieldparam step_name [Symbol] the name of the step being wrapped
    # @return [void]
    # @raise [ArgumentError] if neither method name nor block is provided
    #
    # @example With method name
    #   around_step_run :with_step_timing
    #
    #   def with_step_timing(service, step_name)
    #     start = Time.now
    #     yield
    #     puts "#{step_name} took #{Time.now - start}s"
    #   end
    def around_step_run(method_name = nil, &)
      register_callback(:around_step_run, method_name, &)
    end

    # Registers a callback to run when a step completes successfully (without adding errors).
    #
    # @param method_name [Symbol, nil] name of the instance method to call
    # @yield [service, step_name] block to execute if no method name provided
    # @yieldparam service [Operandi::Base] the service instance
    # @yieldparam step_name [Symbol] the name of the successful step
    # @return [void]
    # @raise [ArgumentError] if neither method name nor block is provided
    #
    # @example With method name
    #   on_step_success :track_step_success
    #
    # @example With block
    #   on_step_success { |service, step_name| Analytics.track("step.success", step: step_name) }
    def on_step_success(method_name = nil, &)
      register_callback(:on_step_success, method_name, &)
    end

    # Registers a callback to run when a step fails (adds errors).
    #
    # @param method_name [Symbol, nil] name of the instance method to call
    # @yield [service, step_name] block to execute if no method name provided
    # @yieldparam service [Operandi::Base] the service instance
    # @yieldparam step_name [Symbol] the name of the failed step
    # @return [void]
    # @raise [ArgumentError] if neither method name nor block is provided
    #
    # @example With method name
    #   on_step_failure :handle_step_error
    #
    # @example With block
    #   on_step_failure { |service, step_name| Rails.logger.error("Step #{step_name} failed") }
    def on_step_failure(method_name = nil, &)
      register_callback(:on_step_failure, method_name, &)
    end

    # Registers a callback to run when a step raises an exception.
    #
    # @param method_name [Symbol, nil] name of the instance method to call
    # @yield [service, step_name, exception] block to execute if no method name provided
    # @yieldparam service [Operandi::Base] the service instance
    # @yieldparam step_name [Symbol] the name of the crashed step
    # @yieldparam exception [Exception] the exception that was raised
    # @return [void]
    # @raise [ArgumentError] if neither method name nor block is provided
    #
    # @example With method name
    #   on_step_crash :report_crash
    #
    # @example With block
    #   on_step_crash { |service, step_name, error| Sentry.capture_exception(error) }
    def on_step_crash(method_name = nil, &)
      register_callback(:on_step_crash, method_name, &)
    end

    # Registers a callback to run before the service starts executing.
    #
    # @param method_name [Symbol, nil] name of the instance method to call
    # @yield [service] block to execute if no method name provided
    # @yieldparam service [Operandi::Base] the service instance
    # @return [void]
    # @raise [ArgumentError] if neither method name nor block is provided
    #
    # @example With method name
    #   before_service_run :log_start
    #
    # @example With block
    #   before_service_run { |service| Rails.logger.info("Starting #{service.class.name}") }
    def before_service_run(method_name = nil, &)
      register_callback(:before_service_run, method_name, &)
    end

    # Registers a callback to run after the service completes (regardless of success/failure).
    #
    # @param method_name [Symbol, nil] name of the instance method to call
    # @yield [service] block to execute if no method name provided
    # @yieldparam service [Operandi::Base] the service instance
    # @return [void]
    # @raise [ArgumentError] if neither method name nor block is provided
    #
    # @example With method name
    #   after_service_run :cleanup
    #
    # @example With block
    #   after_service_run { |service| Rails.logger.info("Done!") }
    def after_service_run(method_name = nil, &)
      register_callback(:after_service_run, method_name, &)
    end

    # Registers an around callback that wraps the entire service execution.
    # The callback must yield to execute the service.
    #
    # @param method_name [Symbol, nil] name of the instance method to call
    # @yield [service] block to execute if no method name provided
    # @yieldparam service [Operandi::Base] the service instance
    # @return [void]
    # @raise [ArgumentError] if neither method name nor block is provided
    #
    # @example With method name
    #   around_service_run :with_timing
    #
    #   def with_timing(service)
    #     start = Time.now
    #     yield
    #     puts "Took #{Time.now - start}s"
    #   end
    def around_service_run(method_name = nil, &)
      register_callback(:around_service_run, method_name, &)
    end

    # Registers a callback to run when the service completes successfully (without errors).
    #
    # @param method_name [Symbol, nil] name of the instance method to call
    # @yield [service] block to execute if no method name provided
    # @yieldparam service [Operandi::Base] the service instance
    # @return [void]
    # @raise [ArgumentError] if neither method name nor block is provided
    #
    # @example With method name
    #   on_service_success :send_notification
    #
    # @example With block
    #   on_service_success { |service| NotificationMailer.success(service.user).deliver_later }
    def on_service_success(method_name = nil, &)
      register_callback(:on_service_success, method_name, &)
    end

    # Registers a callback to run when the service completes with errors.
    #
    # @param method_name [Symbol, nil] name of the instance method to call
    # @yield [service] block to execute if no method name provided
    # @yieldparam service [Operandi::Base] the service instance
    # @return [void]
    # @raise [ArgumentError] if neither method name nor block is provided
    #
    # @example With method name
    #   on_service_failure :log_error
    #
    # @example With block
    #   on_service_failure { |service| Rails.logger.error(service.errors.full_messages) }
    def on_service_failure(method_name = nil, &)
      register_callback(:on_service_failure, method_name, &)
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

    private

    # Registers a callback for a given event.
    #
    # @param event [Symbol] the callback event name
    # @param method_name [Symbol, nil] name of the instance method to call
    # @yield block to execute if no method name provided
    # @return [void]
    # @raise [ArgumentError] if neither method name nor block is provided
    # @api private
    def register_callback(event, method_name = nil, &block)
      callback = method_name || block
      raise ArgumentError, "#{event} requires a method name (symbol) or a block" unless callback

      unless callback.is_a?(Symbol) || callback.is_a?(Proc)
        raise ArgumentError, "#{event} callback must be a Symbol or Proc"
      end

      callbacks_for(event) << callback
    end
  end
end

# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

module Light
  module Services
    # Type alias for callback values (either a method name or a proc)
    Callback = T.type_alias { T.any(Symbol, T.proc.void) }

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
      extend T::Sig

      # Available callback events.
      # @return [Array<Symbol>] list of callback event names
      EVENTS = T.let([
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
      ].freeze, T::Array[Symbol])

      # Run all callbacks for a given event.
      #
      # @param event [Symbol] the callback event name
      # @param args [Array] arguments to pass to callbacks
      # @yield for around callbacks, the block to wrap
      # @return [void]
      sig { params(event: Symbol, args: T.untyped, block: T.nilable(T.proc.void)).void }
      def run_callbacks(event, *args, &block)
        # self.class is the service class that extended CallbackDsl
        callbacks = T.unsafe(self).class.all_callbacks_for(event)

        if event.to_s.start_with?("around_")
          run_around_callbacks(callbacks, args, &T.must(block))
        else
          run_simple_callbacks(callbacks, args)
          block&.call
        end
      end

      private

      sig { params(callbacks: T::Array[Callback], args: T::Array[T.untyped]).void }
      def run_simple_callbacks(callbacks, args)
        callbacks.each do |callback|
          execute_callback(callback, args)
        end
      end

      sig { params(callbacks: T::Array[Callback], args: T::Array[T.untyped], block: T.proc.void).returns(T.untyped) }
      def run_around_callbacks(callbacks, args, &block)
        return yield if callbacks.empty?

        # Build a chain of around callbacks
        chain = T.let(block, T.proc.void)

        callbacks.reverse_each do |callback|
          current_chain = chain
          chain = T.let(
            -> { execute_callback(callback, args, &current_chain) },
            T.proc.void,
          )
        end

        chain.call
      end

      sig { params(callback: T.untyped, args: T::Array[T.untyped], block: T.nilable(T.proc.void)).returns(T.untyped) }
      def execute_callback(callback, args, &block)
        # self is actually a service instance when this module is included
        instance = T.unsafe(self)
        case callback
        when Symbol
          Kernel.block_given? ? instance.send(callback, *args, &block) : instance.send(callback, *args)
        when Proc
          if Kernel.block_given?
            instance.instance_exec(*args, block,
                                   &callback)
          else
            instance.instance_exec(*args, &callback)
          end
        else
          Kernel.raise ArgumentError, "Callback must be a Symbol or Proc, got #{callback.class}"
        end
      end
    end

    # Class methods for registering callbacks.
    # Extend this module in your service class to get callback DSL methods.
    #
    # @example
    #   class MyService < Light::Services::Base
    #     before_service_run :setup
    #     after_service_run :cleanup
    #   end
    module CallbackDsl
      extend T::Sig

      # Registers a callback to run before each step executes.
      #
      # @param method_name [Symbol, nil] name of the instance method to call
      # @yield [service, step_name] block to execute if no method name provided
      # @yieldparam service [Light::Services::Base] the service instance
      # @yieldparam step_name [Symbol] the name of the step about to run
      # @return [void]
      # @raise [ArgumentError] if neither method name nor block is provided
      #
      # @example With method name
      #   before_step_run :log_step_start
      #
      # @example With block
      #   before_step_run { |service, step_name| puts "Starting #{step_name}" }
      sig { params(method_name: T.untyped, block: T.nilable(T.proc.void)).void }
      def before_step_run(method_name = nil, &block)
        register_callback(:before_step_run, method_name, &block)
      end

      # Registers a callback to run after each step executes.
      #
      # @param method_name [Symbol, nil] name of the instance method to call
      # @yield [service, step_name] block to execute if no method name provided
      # @yieldparam service [Light::Services::Base] the service instance
      # @yieldparam step_name [Symbol] the name of the step that just ran
      # @return [void]
      # @raise [ArgumentError] if neither method name nor block is provided
      #
      # @example With method name
      #   after_step_run :log_step_complete
      #
      # @example With block
      #   after_step_run { |service, step_name| puts "Finished #{step_name}" }
      sig { params(method_name: T.untyped, block: T.nilable(T.proc.void)).void }
      def after_step_run(method_name = nil, &block)
        register_callback(:after_step_run, method_name, &block)
      end

      # Registers an around callback that wraps each step execution.
      # The callback must yield to execute the step.
      #
      # @param method_name [Symbol, nil] name of the instance method to call
      # @yield [service, step_name] block to execute if no method name provided
      # @yieldparam service [Light::Services::Base] the service instance
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
      sig { params(method_name: T.untyped, block: T.nilable(T.proc.void)).void }
      def around_step_run(method_name = nil, &block)
        register_callback(:around_step_run, method_name, &block)
      end

      # Registers a callback to run when a step completes successfully (without adding errors).
      #
      # @param method_name [Symbol, nil] name of the instance method to call
      # @yield [service, step_name] block to execute if no method name provided
      # @yieldparam service [Light::Services::Base] the service instance
      # @yieldparam step_name [Symbol] the name of the successful step
      # @return [void]
      # @raise [ArgumentError] if neither method name nor block is provided
      #
      # @example With method name
      #   on_step_success :track_step_success
      #
      # @example With block
      #   on_step_success { |service, step_name| Analytics.track("step.success", step: step_name) }
      sig { params(method_name: T.untyped, block: T.nilable(T.proc.void)).void }
      def on_step_success(method_name = nil, &block)
        register_callback(:on_step_success, method_name, &block)
      end

      # Registers a callback to run when a step fails (adds errors).
      #
      # @param method_name [Symbol, nil] name of the instance method to call
      # @yield [service, step_name] block to execute if no method name provided
      # @yieldparam service [Light::Services::Base] the service instance
      # @yieldparam step_name [Symbol] the name of the failed step
      # @return [void]
      # @raise [ArgumentError] if neither method name nor block is provided
      #
      # @example With method name
      #   on_step_failure :handle_step_error
      #
      # @example With block
      #   on_step_failure { |service, step_name| Rails.logger.error("Step #{step_name} failed") }
      sig { params(method_name: T.untyped, block: T.nilable(T.proc.void)).void }
      def on_step_failure(method_name = nil, &block)
        register_callback(:on_step_failure, method_name, &block)
      end

      # Registers a callback to run when a step raises an exception.
      #
      # @param method_name [Symbol, nil] name of the instance method to call
      # @yield [service, step_name, exception] block to execute if no method name provided
      # @yieldparam service [Light::Services::Base] the service instance
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
      sig { params(method_name: T.untyped, block: T.nilable(T.proc.void)).void }
      def on_step_crash(method_name = nil, &block)
        register_callback(:on_step_crash, method_name, &block)
      end

      # Registers a callback to run before the service starts executing.
      #
      # @param method_name [Symbol, nil] name of the instance method to call
      # @yield [service] block to execute if no method name provided
      # @yieldparam service [Light::Services::Base] the service instance
      # @return [void]
      # @raise [ArgumentError] if neither method name nor block is provided
      #
      # @example With method name
      #   before_service_run :log_start
      #
      # @example With block
      #   before_service_run { |service| Rails.logger.info("Starting #{service.class.name}") }
      sig { params(method_name: T.untyped, block: T.nilable(T.proc.void)).void }
      def before_service_run(method_name = nil, &block)
        register_callback(:before_service_run, method_name, &block)
      end

      # Registers a callback to run after the service completes (regardless of success/failure).
      #
      # @param method_name [Symbol, nil] name of the instance method to call
      # @yield [service] block to execute if no method name provided
      # @yieldparam service [Light::Services::Base] the service instance
      # @return [void]
      # @raise [ArgumentError] if neither method name nor block is provided
      #
      # @example With method name
      #   after_service_run :cleanup
      #
      # @example With block
      #   after_service_run { |service| Rails.logger.info("Done!") }
      sig { params(method_name: T.untyped, block: T.nilable(T.proc.void)).void }
      def after_service_run(method_name = nil, &block)
        register_callback(:after_service_run, method_name, &block)
      end

      # Registers an around callback that wraps the entire service execution.
      # The callback must yield to execute the service.
      #
      # @param method_name [Symbol, nil] name of the instance method to call
      # @yield [service] block to execute if no method name provided
      # @yieldparam service [Light::Services::Base] the service instance
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
      sig { params(method_name: T.untyped, block: T.nilable(T.proc.void)).void }
      def around_service_run(method_name = nil, &block)
        register_callback(:around_service_run, method_name, &block)
      end

      # Registers a callback to run when the service completes successfully (without errors).
      #
      # @param method_name [Symbol, nil] name of the instance method to call
      # @yield [service] block to execute if no method name provided
      # @yieldparam service [Light::Services::Base] the service instance
      # @return [void]
      # @raise [ArgumentError] if neither method name nor block is provided
      #
      # @example With method name
      #   on_service_success :send_notification
      #
      # @example With block
      #   on_service_success { |service| NotificationMailer.success(service.user).deliver_later }
      sig { params(method_name: T.untyped, block: T.nilable(T.proc.void)).void }
      def on_service_success(method_name = nil, &block)
        register_callback(:on_service_success, method_name, &block)
      end

      # Registers a callback to run when the service completes with errors.
      #
      # @param method_name [Symbol, nil] name of the instance method to call
      # @yield [service] block to execute if no method name provided
      # @yieldparam service [Light::Services::Base] the service instance
      # @return [void]
      # @raise [ArgumentError] if neither method name nor block is provided
      #
      # @example With method name
      #   on_service_failure :log_error
      #
      # @example With block
      #   on_service_failure { |service| Rails.logger.error(service.errors.full_messages) }
      sig { params(method_name: T.untyped, block: T.nilable(T.proc.void)).void }
      def on_service_failure(method_name = nil, &block)
        register_callback(:on_service_failure, method_name, &block)
      end

      # Get callbacks defined in this class for a specific event.
      #
      # @param event [Symbol] the callback event name
      # @return [Array<Symbol, Proc>] callbacks for this event
      sig { params(event: Symbol).returns(T::Array[Callback]) }
      def callbacks_for(event)
        @callbacks = T.let(@callbacks, T.nilable(T::Hash[Symbol, T::Array[Callback]]))
        @callbacks ||= {}
        @callbacks[event] ||= []
      end

      # Get all callbacks for an event including inherited ones.
      #
      # @param event [Symbol] the callback event name
      # @return [Array<Symbol, Proc>] all callbacks for this event
      sig { params(event: Symbol).returns(T::Array[Callback]) }
      def all_callbacks_for(event)
        # self is actually a Class when this module is extended
        parent = T.unsafe(self).superclass
        inherited = if parent.respond_to?(:all_callbacks_for)
                      parent.all_callbacks_for(event)
                    else
                      []
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
      sig { params(event: Symbol, method_name: T.untyped, block: T.nilable(T.proc.void)).void }
      def register_callback(event, method_name = nil, &block)
        raw_callback = method_name || block
        Kernel.raise ArgumentError, "#{event} requires a method name (symbol) or a block" unless raw_callback

        unless raw_callback.is_a?(Symbol) || raw_callback.is_a?(Proc)
          Kernel.raise ArgumentError, "#{event} callback must be a Symbol or Proc"
        end

        # Cast to Callback type - Sorbet needs help here since Proc != T.proc.void
        callback = T.cast(raw_callback, Callback)
        callbacks_for(event) << callback
      end
    end
  end
end

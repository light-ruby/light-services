# frozen_string_literal: true
# typed: true

require "sorbet-runtime"

module Light
  module Services
    # Wrapper for running a service with a parent context or custom configuration.
    # Created via {Base.with} method.
    #
    # @example Running with parent service context
    #   ChildService.with(self).run(data: value)
    #
    # @example Running with custom configuration
    #   MyService.with(use_transactions: false).run(name: "test")
    class BaseWithContext
      extend T::Sig

      # Initialize a new context wrapper.
      #
      # @param service_class [Class] the service class to run
      # @param parent_service [Base, nil] parent service for error/warning propagation
      # @param config [Hash] configuration overrides
      # @raise [ArgTypeError] if parent_service is not a Base subclass
      sig { params(service_class: T.class_of(Base), parent_service: T.untyped, config: T::Hash[Symbol, T.untyped]).void }
      def initialize(service_class, parent_service, config)
        @service_class = T.let(service_class, T.class_of(Base))
        @config = T.let(config, T::Hash[Symbol, T.untyped])

        # Validate parent_service before assigning with type
        unless parent_service.nil? || parent_service.is_a?(Light::Services::Base)
          raise Light::Services::ArgTypeError, "#{parent_service.class} - must be a subclass of Light::Services::Base"
        end

        @parent_service = T.let(parent_service, T.nilable(Base))
      end

      # Run the service with the configured context.
      #
      # @param args [Hash] arguments to pass to the service
      # @return [Base] the executed service instance
      sig { params(args: T::Hash[Symbol, T.untyped]).returns(Base) }
      def run(args = {})
        @service_class.new(extend_arguments(args), @config, @parent_service).tap(&:call)
      end

      # Run the service and raise an error if it fails.
      #
      # @param args [Hash] arguments to pass to the service
      # @return [Base] the executed service instance
      # @raise [Error] if the service fails
      sig { params(args: T::Hash[Symbol, T.untyped]).returns(Base) }
      def run!(args = {})
        @config[:raise_on_error] = true
        run(args)
      end

      private

      sig { params(args: T::Hash[Symbol, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
      def extend_arguments(args)
        args = T.unsafe(@parent_service.arguments).dup.extend_with_context(args) if @parent_service
        args[:deepness] += 1 if args[:deepness]

        args
      end
    end
  end
end

# frozen_string_literal: true

module RuboCop
  module Cop
    module LightServices
      # Prevents direct instantiation of service classes with `.new`.
      # Services should be called using `.run`, `.run!`, or `.call`.
      #
      # @example
      #   # bad
      #   UserService.new(name: "John")
      #   User::Create.new(params: {})
      #
      #   # good
      #   UserService.run(name: "John")
      #   UserService.run!(name: "John")
      #   UserService.call(name: "John")
      #   User::Create.run(params: {})
      #
      # @example ServicePattern: 'Service$' (default)
      #   # Matches class names ending with "Service"
      #   UserService.new  # offense
      #   UserCreator.new  # no offense (doesn't match pattern)
      #
      # @example ServicePattern: '(Service|Creator)$'
      #   # Matches class names ending with "Service" or "Creator"
      #   UserService.new  # offense
      #   UserCreator.new  # offense
      #
      class NoDirectInstantiation < Base
        MSG = "Use `.run`, `.run!`, or `.call` instead of `.new` for service classes."

        RESTRICT_ON_SEND = [:new].freeze

        def on_send(node)
          return unless node.method_name == :new
          return unless service_class?(node.receiver)

          add_offense(node)
        end

        private

        def service_class?(node)
          return false unless node

          class_name = extract_class_name(node)
          return false unless class_name

          pattern = cop_config.fetch("ServicePattern", "Service$")
          class_name.match?(Regexp.new(pattern))
        end

        def extract_class_name(node)
          case node.type
          when :const
            node.const_name
          when :send
            # For chained constants like User::Create
            node.source
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module RuboCop
  module Cop
    module Operandi
      # Detects when `.run` or `.run!` is called with a hash argument instead of keyword arguments.
      #
      # Since Operandi services now only accept keyword arguments, passing a hash variable
      # or hash expression will cause an error. Use keyword splatting (`**`) to convert
      # hash arguments to keyword arguments.
      #
      # @safety
      #   This cop is disabled by default because it may produce false positives
      #   when `.run` is called on non-Operandi classes.
      #
      # @example
      #   # bad
      #   UserService.run(args)
      #   UserService.run!(params)
      #   UserService.run(args.merge(new: true))
      #   UserService.run({ name: "John" })
      #   Auth::SignIn.run(service_args)
      #
      #   # good
      #   UserService.run(name: "John")
      #   UserService.run(**args)
      #   UserService.run(**args.merge(new: true))
      #   UserService.run(**args, new: true)
      #   Auth::SignIn.run(**service_args)
      #
      # @example ServicePattern: nil (default - checks all classes)
      #   # Checks all .run and .run! calls
      #   UserService.run(args)       # offense
      #   Auth::SignIn.run(args)      # offense
      #   SomeClass.run(args)         # offense
      #
      # @example ServicePattern: 'Service$'
      #   # Only matches class names ending with "Service"
      #   UserService.run(args)       # offense
      #   Auth::SignIn.run(args)      # no offense (doesn't match pattern)
      #
      class NoHashArgument < Base
        MSG = "Use keyword arguments or `**` splat instead of hash argument for `.%<method>s`."

        RESTRICT_ON_SEND = [:run, :run!].freeze

        def on_send(node)
          return unless RESTRICT_ON_SEND.include?(node.method_name)
          return unless service_class?(node.receiver)
          return if node.arguments.empty?
          return if valid_arguments?(node.arguments)

          add_offense(node, message: format(MSG, method: node.method_name), severity: :fatal)
        end

        private

        def valid_arguments?(arguments)
          arguments.all? do |arg|
            case arg.type
            when :block_pass
              # Block pass (&block) is always valid
              true
            when :hash
              # Hash node can be:
              # - Implicit hash for keyword args: run(foo: bar) - braces? returns false
              # - Explicit hash literal: run({ foo: bar }) - braces? returns true
              # Only implicit hash (keyword args) is valid
              !arg.braces?
            else
              # Any other type (lvar, send, ivar, etc.) is a hash variable - invalid
              false
            end
          end
        end

        def service_class?(node)
          return false unless node

          class_name = extract_class_name(node)
          return false unless class_name

          pattern = cop_config["ServicePattern"]
          return true if pattern.nil? || pattern.empty?

          class_name.match?(Regexp.new(pattern))
        end

        def extract_class_name(node)
          case node.type
          when :const
            node.const_name
          when :send
            # For chained constants like User::Create or method calls
            node.source
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

# Collection to store, merge and validate arguments
module Light
  module Services
    module Collection
      class Arguments < Base
        def extend_with_context(args)
          settings_collection.each do |name, arg|
            next if !arg.context || args.key?(name) || !key?(name)

            args[arg.name] = get(name)
          end

          args
        end

        def validate!
          settings_collection.each do |name, arg|
            next if arg.optional && (!key?(name) || get(name).nil?)

            arg.validate_type!(get(name))
          end
        end

        private

        def settings_collection
          @instance.class.arguments
        end
      end
    end
  end
end

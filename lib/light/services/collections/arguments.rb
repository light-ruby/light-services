# frozen_string_literal: true

# Collection to store, merge and validate arguments
module Light
  module Services
    module Collections
      class Arguments < Base
        def extend_with_context(args)
          items_collection.each do |name, argument|
            next if !argument.context || args.key?(name) || !key?(name)

            args[argument.name] = get(name)
          end

          args
        end

        def validate!
          items_collection.each do |name, argument|
            next if argument.optional && (!key?(name) || get(name).nil?)

            argument.validate_type!(get(name))
          end
        end

        private

        def items_collection
          @instance.class.arguments
        end
      end
    end
  end
end

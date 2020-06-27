module Light
  module Services
    module Collection
      class Arguments < Base
        def extend_with_context(args)
          settings_collection.select(&:context).each do |settings|
            next if args.key?(settings.name) || !key?(settings.name)

            args[settings.name] = get(settings.name)
          end

          args
        end

        def validate!
          settings_collection.each do |settings|
            next if settings.optional && !key?(settings.name)

            settings.valid_type?(get(settings.name))
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

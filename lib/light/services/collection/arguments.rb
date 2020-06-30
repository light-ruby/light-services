# frozen_string_literal: true

module Light
  module Services
    module Collection
      class Arguments < Base
        def extend_with_context(args)
          settings_collection.each do |name, settings|
            next if !settings.context || args.key?(name) || !key?(name)

            args[settings.name] = get(name)
          end

          args
        end

        def validate!
          settings_collection.each do |name, settings|
            next if settings.optional && (!key?(name) || get(name).nil?)

            settings.valid_type?(get(name))
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

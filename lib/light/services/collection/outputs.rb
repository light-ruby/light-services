# frozen_string_literal: true

# Collection to store and validate outputs values
module Light
  module Services
    module Collection
      class Outputs < Base
        def validate!
          settings_collection.each do |name, output|
            next if output.optional && (!key?(name) || get(name).nil?)

            output.validate_type!(get(name))
          end
        end

        private

        def settings_collection
          @instance.class.outputs
        end
      end
    end
  end
end

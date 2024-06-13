# frozen_string_literal: true

# Collection to store outputs values
module Light
  module Services
    module Collections
      class Outputs < Base
        private

        def items_collection
          @instance.class.outputs
        end
      end
    end
  end
end

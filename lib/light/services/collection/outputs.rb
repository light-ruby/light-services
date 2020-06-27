module Light
  module Services
    module Collection
      class Outputs < Base
        private

        def settings_collection
          @instance.class.outputs
        end
      end
    end
  end
end

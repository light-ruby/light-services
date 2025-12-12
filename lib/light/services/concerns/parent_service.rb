# frozen_string_literal: true

module Light
  module Services
    module Concerns
      # Handles copying errors and warnings to parent services
      module ParentService
        private

        # Copy warnings from this service to parent service
        def copy_warnings_to_parent_service
          return if !@parent_service || !@config[:load_warnings]

          @parent_service.warnings.copy_from(
            @warnings,
            break: @config[:self_break_on_warning],
            rollback: @config[:self_rollback_on_warning],
          )
        end

        # Copy errors from this service to parent service
        def copy_errors_to_parent_service
          return if !@parent_service || !@config[:load_errors]

          @parent_service.errors.copy_from(
            @errors,
            break: @config[:self_break_on_error],
            rollback: @config[:self_rollback_on_error],
          )
        end
      end
    end
  end
end

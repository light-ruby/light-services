# frozen_string_literal: true

# Shared type validation logic for arguments and outputs
module Light
  module Services
    module Settings
      module TypeValidatable
        def validate_type!(value)
          return if !@type || [*@type].any? { |type| matches_type?(value, type) }

          raise Light::Services::ArgTypeError, type_error_message(value)
        end

        private

        def matches_type?(value, type)
          case type
          when :boolean
            value.is_a?(TrueClass) || value.is_a?(FalseClass)
          when Symbol
            symbolized_class_name(value) == type
          else
            value.is_a?(type)
          end
        end

        def symbolized_class_name(value)
          klass = value.class

          @type_cache ||= {}
          @type_cache[klass] ||= klass
            .name
            .gsub("::", "/")
            .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
            .gsub(/([a-z\d])([A-Z])/, '\1_\2')
            .tr("-", "_")
            .downcase
            .to_sym
        end

        def type_error_message(value)
          "#{@service_class} #{setting_type} `#{name}` must be " \
            "a #{[*@type].join(', ')} (currently: #{value.class})"
        end

        def setting_type
          raise NotImplementedError, "Subclasses must implement #setting_type"
        end
      end
    end
  end
end

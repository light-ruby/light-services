# frozen_string_literal: true

module Light
  module Services
    module Callbacks
      def self.included(base)
        base.extend ClassMethods
        base.class_eval do
          class << self
            attr_accessor :callbacks
          end
        end
      end

      private

      def run_callbacks(type, options = {})
        callbacks_by(type).each do |callback|
          break if !success? && !options[:force_run]
          send(callback[:method_name])
        end
      end

      def callbacks_by(type)
        all_callbacks.select { |callback| callback[:type] == type }
      end

      def all_callbacks
        return @_all_callbacks if defined?(@_all_callbacks)
        @_all_callbacks = self.class.ancestors.select { |klass| klass.ancestors.include?(::Light::Services::Base) }
                              .map(&:callbacks).compact.flatten.uniq
      end

      module ClassMethods
        def before(method_name)
          set_callback(:before, method_name)
        end

        def after(method_name)
          set_callback(:after, method_name)
        end

        def finally(method_name)
          set_callback(:finally, method_name)
        end

        def set_callback(type, method_name)
          self.callbacks ||= []
          self.callbacks << { type: type, method_name: method_name }
        end
      end
    end
  end
end

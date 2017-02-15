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

      def run_callbacks(type, opts = {})
        opts[:break] = true unless opts.key?(:break)

        callbacks = (self.class.callbacks || []).select { |callback| callback[:type] == type }
        callbacks.each do |callback|
          break if !success? && opts[:break]
          send(callback[:method])
        end
      end

      module ClassMethods
        def before(method)
          set_callback(:before, method)
        end

        def after(method)
          set_callback(:after, method)
        end

        def finally(method)
          set_callback(:finally, method)
        end

        def set_callback(type, method)
          self.callbacks ||= []
          self.callbacks << { type: type, method: method }
        end
      end
    end
  end
end

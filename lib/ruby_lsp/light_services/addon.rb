# frozen_string_literal: true

require_relative "indexing_enhancement"

# Declare version compatibility without runtime dependency on ruby-lsp
RubyLsp::Addon.depend_on_ruby_lsp!("~> 0.26")

module RubyLsp
  module LightServices
    class Addon < ::RubyLsp::Addon
      def activate(_global_state, message_queue)
        @message_queue = message_queue
      end

      def deactivate; end

      def name
        "Ruby LSP Light Services"
      end

      def version
        Light::Services::VERSION
      end
    end
  end
end

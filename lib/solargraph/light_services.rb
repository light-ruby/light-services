# frozen_string_literal: true

require_relative "light_services/convention"

module Solargraph
  module LightServices
    # Register the convention with Solargraph
    Solargraph::Convention.register(Convention)
  end
end


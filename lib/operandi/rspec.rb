# frozen_string_literal: true

require "operandi"

require_relative "rspec/matchers/define_argument"
require_relative "rspec/matchers/define_output"
require_relative "rspec/matchers/define_step"
require_relative "rspec/matchers/have_error_on"
require_relative "rspec/matchers/have_warning_on"
require_relative "rspec/matchers/execute_step"
require_relative "rspec/matchers/trigger_callback"

RSpec.configure do |config|
  config.include Operandi::RSpec::Matchers
end

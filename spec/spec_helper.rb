# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'light/services'

# Load internal resources
require_relative 'internal/structures/user'
require_relative 'internal/services/user/register'
require_relative 'internal/services/user/update'

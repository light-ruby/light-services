require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'light/service'

# Load internal resources
require_relative 'internal/structures/user'
require_relative 'internal/services/user/register'
require_relative 'internal/services/user/update'

# encoding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'light/services/version'

Gem::Specification.new do |spec|
  spec.name          = 'light-services'
  spec.version       = Light::Services::VERSION
  spec.authors       = ['Andrew Emelianenko']
  spec.email         = ['emelianenko.web@gmail.com']

  spec.summary       = 'Light pattern Services Object for Ruby/Rails'
  spec.description   = 'Light pattern Services Object for Ruby/Rails from Light Ruby'
  spec.homepage      = 'https://github.com/light-ruby/light-services'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`
                       .split("\x0")
                       .reject { |f| f.match(%r{^(test|spec|features)/}) }

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'rails', '> 4.0'

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'appraisal', '~> 2.1'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'simplecov', '~> 0.11.2'
  spec.add_development_dependency 'codeclimate-test-reporter'
end

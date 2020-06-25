# frozen_string_literal: true

require_relative "lib/light/services/version"

Gem::Specification.new do |spec|
  spec.name          = "light-services"
  spec.version       = Light::Services::VERSION
  spec.authors       = ["Andrew Emelianenko"]
  spec.email         = ["emelianenko.web@gmail.com"]

  spec.summary       = "Light pattern Services Object for Ruby/Rails"
  spec.description   = "Light pattern Services Object for Ruby/Rails"
  spec.homepage      = "https://github.com/light-ruby/light-services"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/light-ruby/light-services"
  spec.metadata["changelog_uri"] = "https://github.com/light-ruby/light-services/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end

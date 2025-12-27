# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :test do
  gem "sorbet-runtime"

  gem "activerecord", "< 8"
  gem "connection_pool", "< 3"
  gem "database_cleaner-active_record"
  gem "sqlite3"

  gem "rake"
  gem "rspec"
  gem "rspec-benchmark"
  gem "simplecov"
  gem "simplecov-cobertura"

  gem "rubocop"
  gem "rubocop-performance"
  gem "rubocop-rake"
  gem "rubocop-rspec"

  # Fix OpenSSL 3.x CRL verification issues
  gem "openssl", "4.0.0"
end

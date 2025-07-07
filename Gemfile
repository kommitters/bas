# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in bas.gemspec
gemspec

gem "rake", "~> 13.0"

gem "rspec", "~> 3.0"
gem "rubocop", "~> 1.21"
gem "simplecov", require: false, group: :test
gem "simplecov-lcov", "~> 0.8.0"

gem "vcr"
gem "webmock"

gem gem "faraday", "~> 2.9"

gem "json", "~> 2.8"

gem "elasticsearch", "~> 8.0"
gem "httparty"
gem "pg", "~> 1.5", ">= 1.5.4"

group :test do
  gem "faraday-retry"
  gem "gmail_xoauth", "~> 0.4.1"
  gem "google-api-client", "~> 0.53"
  gem "jwt", "~> 2.8.1"
  gem "md_to_notion", "~> 0.1.4"
  gem "net-imap", "~> 0.4.10"
  gem "net-smtp", "~> 0.4.0.1"
  gem "octokit", "~> 8.1.0"
  gem "openssl", "~> 3.2"
  gem "timecop"
end

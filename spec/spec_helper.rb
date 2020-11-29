require "bundler/setup"
require "pry"
require "rspec-html-matchers"
require "rbexy"

# Rails dummy app for integration tests
ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../dummy/config/environment.rb', __FILE__)
require "rspec/rails"

RSpec.configure do |config|
  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
  config.include RSpecHtmlMatchers

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.filter_run_when_matching :focus
end

require "bundler/setup"
require "pry"
require "rspec-html-matchers"
require "rbexy"
require "memory_profiler"

# Rails dummy app for integration tests
ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../dummy/config/environment.rb', __FILE__)
require "rspec/rails"

module PerfHelpers
  def self.results
    @results
  end

  def self.results=(value)
    @results = value
  end

  def self.setup(config)
    config.before(:suite) { PerfHelpers.results = [] }
    config.before(:each) { |e| @current_perf_example = e }
    config.after(:suite) do
      if ENV.include?("PROFILER")
        puts; puts; puts
        puts "Profiler:"

        PerfHelpers.results.each.with_index do |result, i|
          puts; puts <<-REPORT
  #{i+1}) #{result[:metadata][:full_description]}
     #{ENV["PROFILER"] == "verbose" ? result[:report].pretty_print : "#{result[:report].total_allocated_memsize} bytes (#{result[:report].total_allocated} objects)"}
     #{result[:metadata][:location]}
          REPORT
        end
      end
    end
  end

  def profile
    result = nil

    report = MemoryProfiler.report do
      result = yield
    end

    PerfHelpers.results << {
      metadata: @current_perf_example.metadata,
      report: report
    }

    result
  end
end

RSpec.configure do |config|
  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
  config.include RSpecHtmlMatchers

  config.include PerfHelpers
  PerfHelpers.setup(config)

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.filter_run_when_matching :focus
end

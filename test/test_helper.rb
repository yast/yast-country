root_location = File.expand_path("..", __dir__)
inc_dirs = Dir.glob("#{root_location}/*/src")
ENV["Y2DIR"] = inc_dirs.join(":")

ENV["LANG"] = "en_US.UTF-8"
ENV["LC_ALL"] = "en_US.UTF-8"

require "yast"
require "rspec"
require "yast/rspec"

RSpec.configure do |config|
  config.mock_with :rspec do |c|
    # make sure we mock only the existing methods
    # https://relishapp.com/rspec/rspec-mocks/v/3-0/docs/verifying-doubles/partial-doubles
    c.verify_partial_doubles = true
  end
end

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/test/"
    add_filter "/*/test/"
  end

  # for correct coverage report we need to load all ruby files
  SimpleCov.track_files("#{root_location}/**/src/**/*.rb")

  # additionally use the LCOV format for on-line code coverage reporting at CI
  if ENV["CI"] || ENV["COVERAGE_LCOV"]
    require "simplecov-lcov"

    SimpleCov::Formatter::LcovFormatter.config do |c|
      c.report_with_single_file = true
      # this is the default Coveralls GitHub Action location
      # https://github.com/marketplace/actions/coveralls-github-action
      c.single_report_path = "coverage/lcov.info"
    end

    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::LcovFormatter
    ]
  end
end

# stub classes from other modules to avoid build dependencies
Yast::RSpec::Helpers.define_yast_module("AutoInstall")

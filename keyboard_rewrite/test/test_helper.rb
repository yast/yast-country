require "yast"
require "yast/rspec"
require_relative "helpers"

SRC_PATH = File.expand_path("../../src", __FILE__)
DATA_PATH = File.join(File.expand_path(File.dirname(__FILE__)), "data")
ENV["Y2DIR"] = SRC_PATH

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/test/"
  end

  # for coverage we need to load all ruby files
  Dir["#{SRC_PATH}/lib/**/**/*.rb"].each { |f| require_relative f }

  # use coveralls for on-line code coverage reporting at Travis CI
  if ENV["TRAVIS"]
    require "coveralls"
    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      Coveralls::SimpleCov::Formatter
    ]
  end
end

RSpec.configure do |config|
  config.include Helpers    # custom helpers
end


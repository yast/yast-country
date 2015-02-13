root_location = File.expand_path("../../", __FILE__)
inc_dirs = Dir.glob("#{root_location}/*/src")
ENV["Y2DIR"] = inc_dirs.join(":")

require "yast"

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start

  # for correct coverage report we need to load all ruby files
  Dir["#{root_location}/*/src/{module,include,lib}/**/*.rb"].each { |f| require_relative f }

  # use coveralls for on-line code coverage reporting at Travis CI
  if ENV["TRAVIS"]
    require "coveralls"
    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      Coveralls::SimpleCov::Formatter
    ]
  end
end

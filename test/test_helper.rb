root_location = File.expand_path("../../", __FILE__)
inc_dirs = Dir.glob("#{root_location}/*/src")
ENV["Y2DIR"] = inc_dirs.join(":")

ENV["LANG"] = "en_US.UTF-8"
ENV["LC_ALL"] = "en_US.UTF-8"

require "yast"
require "rspec"
require "yast/rspec"

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/test/"
    add_filter "/*/test/"
  end

  # for correct coverage report we need to load all ruby files
  SimpleCov.track_files("#{root_location}/**/src/**/*.rb")

  # use coveralls for on-line code coverage reporting at Travis CI
  if ENV["TRAVIS"]
    require "coveralls"
    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      Coveralls::SimpleCov::Formatter
    ]
  end
end

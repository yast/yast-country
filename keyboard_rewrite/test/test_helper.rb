SRC_PATH = File.expand_path("../../src", __FILE__)
DATA_PATH = File.join(File.expand_path(File.dirname(__FILE__)), "data")
ENV["Y2DIR"] = SRC_PATH

require "yast"
require "yast/rspec"
require_relative "keyboard_spec_helper"

RSpec.configure do |config|
  config.include KeyboardSpecHelper    # custom helpers
end


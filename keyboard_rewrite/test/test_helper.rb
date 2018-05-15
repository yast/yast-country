require_relative "../../test/test_helper.rb"
require_relative "keyboard_spec_helper"

RSpec.configure do |config|
  config.include KeyboardSpecHelper # custom helpers
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end

require "cheetah"
require_relative "./strategies/systemd_strategy.rb"

module Y2Keyboard
  # This class represents a keyboard layout. Also have methods to interact with the system.
  class KeyboardLayout
    attr_reader :code
    attr_reader :description

    def initialize(code, description)
      @code = code
      @description = description
    end
  end
end

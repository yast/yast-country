require "cheetah"
require "y2keyboard/strategies/systemd_strategy.rb"

module Y2Keyboard
  # This class represents a keyboard layout. Also have methods to interact with the system.
  class KeyboardLayout
    include Yast::Logger

    attr_reader :code
    attr_reader :description

    def initialize(code, description)
      @code = code
      @description = description
    end

    def self.all
      Y2Keyboard::Strategies::SystemdStrategy.all
    end

    def self.apply_layout(keyboard_layout)
      Y2Keyboard::Strategies::SystemdStrategy.apply_layout(keyboard_layout)
    end

    def self.load_layout(keyboard_layout)
      Y2Keyboard::Strategies::SystemdStrategy.load_layout(keyboard_layout)
    end

    def self.current_layout
      Y2Keyboard::Strategies::SystemdStrategy.current_layout
    end
  end
end

require "cheetah"
require "y2_keyboard/keyboard_layout"

module Y2Keyboard
  class KeyboardLayoutRepository
    def self.load
      raw_layouts = Cheetah.run("localectl", "list-x11-keymap-layouts", stdout: :capture)
      raw_layouts.lines.map { |string| KeyboardLayout.new(string.split.first) }
    end
  end
end
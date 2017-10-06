require "cheetah"
require "y2_keyboard/keyboard_layout"

module Y2Keyboard
  class KeyboardLayoutRepository

    LAYOUT_CODE_DESCRIPTIONS = {
      'es' => 'Spanish' 
    }

    def self.load
      raw_layouts = Cheetah.run("localectl", "list-keymaps", stdout: :capture)
      raw_layouts.lines.map { |string| KeyboardLayout.new(string.split.first, LAYOUT_CODE_DESCRIPTIONS[string.split.first]) }
    end
  end
end
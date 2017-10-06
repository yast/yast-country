require "cheetah"
require "y2_keyboard/keyboard_layout"

module Y2Keyboard
  class KeyboardLayoutRepository

    LAYOUT_CODE_DESCRIPTIONS = {
      'es' => 'Spanish',
      'fr' => 'French',
      'us' => 'English (US)'
    }

    def self.load
      raw_layouts = Cheetah.run("localectl", "list-keymaps", stdout: :capture)
      layout_codes = raw_layouts.lines.map { |string| string.split.first }
      layout_codes_with_description = layout_codes.select { |code| LAYOUT_CODE_DESCRIPTIONS.has_key?(code) }
      layout_codes_with_description.map { |code| KeyboardLayout.new(code, LAYOUT_CODE_DESCRIPTIONS[code]) }
    end
  end
end
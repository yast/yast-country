require "cheetah"

module Y2Keyboard
  class KeyboardLayout
    attr_reader :code
    attr_reader :description

    LAYOUT_CODE_DESCRIPTIONS = {
      "es" => "Spanish",
      "fr" => "French",
      "us" => "English (US)"
    }

    def initialize(code, description)
      @code = code
      @description = description
    end

    def self.load
      raw_layouts = Cheetah.run("localectl", "list-keymaps", stdout: :capture)
      layout_codes = raw_layouts.lines.map { |string| string.split.first }
      codes_with_description = layout_codes.select { |code| LAYOUT_CODE_DESCRIPTIONS.key?(code) }
      codes_with_description.map { |code| KeyboardLayout.new(code, LAYOUT_CODE_DESCRIPTIONS[code]) }
    end

    def self.set_layout(keyboard_layout)
      Cheetah.run("localectl", "set-keymap", "--no-convert", keyboard_layout.code)
    end
  end
end

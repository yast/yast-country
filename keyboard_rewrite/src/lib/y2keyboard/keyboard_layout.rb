require "cheetah"

Yast.import "UI"

module Y2Keyboard
  class KeyboardLayout
    attr_reader :code
    attr_reader :description

    LAYOUT_CODE_DESCRIPTIONS = {
      "gb" => "English (UK)",
      "es" => "Spanish",
      "fr" => "French",
      "us" => "English (US)"
    }

    def initialize(code, description)
      @code = code
      @description = description
    end

    def self.all
      raw_layouts = Cheetah.run("localectl", "list-keymaps", stdout: :capture)
      codes = raw_layouts.lines.map(&:strip)
      codes_with_description = codes.select { |code| LAYOUT_CODE_DESCRIPTIONS.key?(code) }
      codes_with_description.map { |code| KeyboardLayout.new(code, LAYOUT_CODE_DESCRIPTIONS[code]) }
    end

    def self.set_layout(keyboard_layout)
      Cheetah.run("localectl", "set-keymap", keyboard_layout.code)
    end

    def self.load_layout(keyboard_layout)
      Cheetah.run("setxkbmap", keyboard_layout.code) if !Yast::UI.TextMode
      Cheetah.run("loadkeys", keyboard_layout.code) if Yast::UI.TextMode
    end

    def self.get_current_layout()
      get_layout(get_current_layout_code())
    end

    def self.get_layout(code)
      all().find { |x| x.code == code }
    end

    def self.get_current_layout_code()
      output = Cheetah.run("localectl", "status", stdout: :capture)
      output.lines.map { |x| x.strip }.find { |x| x.start_with?("VC Keymap:") }.split.last
    end

    private_class_method :get_current_layout_code, :get_layout
  end
end

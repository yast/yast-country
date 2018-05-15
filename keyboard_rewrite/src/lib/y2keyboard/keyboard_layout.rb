require "cheetah"

Yast.import "UI"

module Y2Keyboard
  class KeyboardLayout
    include Yast::Logger

    attr_reader :code
    attr_reader :description

    LAYOUT_CODE_DESCRIPTIONS = {
      "gb" => "English (UK)",
      "es" => "Spanish",
      "fr" => "French",
      "us" => "English (US)"
    }.freeze

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

    def self.apply_layout(keyboard_layout)
      Cheetah.run("localectl", "set-keymap", keyboard_layout.code)
    end

    def self.load_layout(keyboard_layout)
      Cheetah.run("setxkbmap", keyboard_layout.code) if !Yast::UI.TextMode
      begin
        Cheetah.run("loadkeys", keyboard_layout.code) if Yast::UI.TextMode
      rescue Cheetah::ExecutionFailed => e
        log.info(e.message)
        log.info("Error output:    #{e.stderr}")
      end
    end

    def self.current_layout
      find_layout_with(current_layout_code)
    end

    def self.find_layout_with(code)
      all.find { |x| x.code == code }
    end

    def self.current_layout_code
      output = Cheetah.run("localectl", "status", stdout: :capture)
      output.lines.map(&:strip).find { |x| x.start_with?("VC Keymap:") }.split.last
    end

    private_class_method :current_layout_code, :find_layout_with
  end
end

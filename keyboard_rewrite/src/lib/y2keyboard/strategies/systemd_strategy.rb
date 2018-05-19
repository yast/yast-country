require "cheetah"
require_relative "../keyboard_layout"

module Y2Keyboard
  module Strategies
    # Class to deal with systemd keyboard configuration
    class SystemdStrategy
      include Yast::Logger

      LAYOUT_CODE_DESCRIPTIONS = {
        "gb" => "English (UK)",
        "es" => "Spanish",
        "fr" => "French",
        "us" => "English (US)"
      }.freeze

      def all
        raw_layouts = Cheetah.run("localectl", "list-keymaps", stdout: :capture)
        codes = raw_layouts.lines.map(&:strip)
        codes_with_description = codes.select { |code| LAYOUT_CODE_DESCRIPTIONS.key?(code) }
        codes_with_description.map { |x| KeyboardLayout.new(x, LAYOUT_CODE_DESCRIPTIONS[x]) }
      end

      def apply_layout(keyboard_layout)
        Cheetah.run("localectl", "set-keymap", keyboard_layout.code)
      end

      def load_layout(keyboard_layout)
        Cheetah.run("setxkbmap", keyboard_layout.code) if !Yast::UI.TextMode
        begin
          Cheetah.run("loadkeys", keyboard_layout.code) if Yast::UI.TextMode
        rescue Cheetah::ExecutionFailed => e
          log.info(e.message)
          log.info("Error output:    #{e.stderr}")
        end
      end

      def current_layout
        find_layout_with(current_layout_code)
      end

      def find_layout_with(code)
        all.find { |x| x.code == code }
      end

      def current_layout_code
        output = Cheetah.run("localectl", "status", stdout: :capture)
        output.lines.map(&:strip).find { |x| x.start_with?("VC Keymap:") }.split.last
      end

      private :current_layout_code, :find_layout_with
    end
  end
end

require "cheetah"
require_relative "../keyboard_layout"
require "yaml"

module Y2Keyboard
  module Strategies
    # Class to deal with systemd keyboard configuration
    class SystemdStrategy
      include Yast::Logger

      def initialize(layout_definitions)
        @layout_definitions = layout_definitions
      end

      def all
        raw_layouts = Cheetah.run("localectl", "list-keymaps", stdout: :capture)
        codes = raw_layouts.lines.map(&:strip)
        codes_with_description = codes.select { |code| @layout_definitions.key?(code) }
        codes_with_description.map do |x|
          KeyboardLayout.new(x, @layout_definitions[x]["description"])
        end
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

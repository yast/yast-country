require "cheetah"
require_relative "../keyboard_layout"
require "yaml"

module Y2Keyboard
  module Strategies
    # Class to deal with systemd keyboard configuration management.
    class SystemdStrategy
      include Yast::Logger

      def initialize(layout_definitions)
        @layout_definitions = layout_definitions
      end

      # @return [Array<KeyboardLayout>] an array with all available keyboard layouts.
      def all
        raw_layouts = Cheetah.run("localectl", "list-keymaps", stdout: :capture)
        codes = raw_layouts.lines.map(&:strip)
        layouts = @layout_definitions.select { |x| codes.include?(x["code"]) }
        layouts.map { |x| KeyboardLayout.new(x["code"], x["description"]) }
      end

      # Apply a new keyboard layout in the system.
      # @param keyboard_layout [KeyboardLayout] the keyboard layout to apply in the system.
      def apply_layout(keyboard_layout)
        Cheetah.run("localectl", "set-keymap", keyboard_layout.code)
      end

      # Load x11 or virtual console keys on the fly.
      # @param keyboard_layout [KeyboardLayout] the keyboard layout to load.
      def load_layout(keyboard_layout)
        load_x11_layout(keyboard_layout) if !Yast::UI.TextMode
        begin
          Cheetah.run("loadkeys", keyboard_layout.code) if Yast::UI.TextMode
        rescue Cheetah::ExecutionFailed => e
          log.info(e.message)
          log.info("Error output:    #{e.stderr}")
        end
      end

      # Load x11 keys on the fly.
      # @param keyboard_layout [KeyboardLayout] the keyboard layout to load.
      def load_x11_layout(keyboard_layout)
        output = Cheetah.run("/usr/sbin/xkbctrl", keyboard_layout.code, stdout: :capture)
        arguments = get_value_from_output(output, "\"Apply\"").tr("\"", "")
        setxkbmap_array_arguments = arguments.split.unshift("setxkbmap")
        Cheetah.run(setxkbmap_array_arguments)
      end

      # @return [KeyboardLayout] the current keyboard layout in the system.
      def current_layout
        find_layout_with(current_layout_code)
      end

      def find_layout_with(code)
        all.find { |x| x.code == code }
      end

      def current_layout_code
        output = Cheetah.run("localectl", "status", stdout: :capture)
        get_value_from_output(output, "VC Keymap:").strip
      end

      def get_value_from_output(output, property_name)
        output.lines.map(&:strip).find { |x| x.start_with?(property_name) }.split(":", 2).last
      end

      private :current_layout_code, :find_layout_with, :get_value_from_output, :load_x11_layout
    end
  end
end

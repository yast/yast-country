# Copyright (c) [2018] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require "cheetah"
require_relative "../keyboard_layout"

module Y2Keyboard
  module Strategies
    # Class to deal with systemd keyboard configuration management.
    class SystemdStrategy

      # @return [Array<String>] an array with all available systemd keyboard layouts codes.
      def codes
        raw_layouts = Cheetah.run("localectl", "list-keymaps", stdout: :capture)
        raw_layouts.lines.map(&:strip)
      end

      # Use systemd-localed to apply a new keyboard layout in the system.
      # @param keyboard_layout [KeyboardLayout] the keyboard layout to apply in the system.
      def apply_layout(keyboard_layout)
        Cheetah.run("localectl", "set-keymap", keyboard_layout.code)
      end

      # @return [KeyboardLayout] the current keyboard layout in the system.
      def current_layout
        output = Cheetah.run("localectl", "status", stdout: :capture)
        get_value_from_output(output, "VC Keymap:").strip
      end

      def get_value_from_output(output, property_name)
        output.lines.map(&:strip).find { |x| x.start_with?(property_name) }.split(":", 2).last
      end

      private :get_value_from_output
    end
  end
end

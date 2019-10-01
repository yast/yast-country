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

require "yast2/execute"

module Y2Keyboard
  module Strategies
    # Class to deal with systemd keyboard configuration management.
    class SystemdStrategy
      # @return [Array<String>] an array with all available systemd keyboard layouts codes.
      def codes
        raw_layouts = Yast::Execute.on_target!("localectl", "list-keymaps", stdout: :capture)
        raw_layouts.lines.map(&:strip)
      end

      # Use systemd to apply a new keyboard layout in the system.
      # @param keyboard_code [String] the keyboard layout to apply in the system.
      def apply_layout(keyboard_code)
        if Yast::Stage.initial
          # systemd is not available here (inst-sys).
          # do use --root option, running in chroot does not work (bsc#1074481)
          Yast::Execute.locally!("systemd-firstboot", "--root", Installation.destdir, "--keymap", keyboard_code)
        else
          Yast::Execute.on_target!("localectl", "set-keymap", keyboard_code)
        end
      end

      # @return [KeyboardLayout] the current keyboard layout in the system.
      def current_layout
        output = Yast::Execute.on_target!("localectl", "status", stdout: :capture)
        get_value_from_output(output, "VC Keymap:").strip
      end

    private

      def get_value_from_output(output, property_name)
        output.lines.map(&:strip).find { |x| x.start_with?(property_name) }.split(":", 2).last
      end
    end
  end
end

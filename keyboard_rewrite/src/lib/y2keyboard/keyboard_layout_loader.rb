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

module Y2Keyboard
    # Class to change keyboard layout on the fly.
    class KeyboardLayoutLoader
      include Yast::Logger

      # Load x11 or virtual console keys on the fly.
      # @param keyboard_layout [KeyboardLayout] the keyboard layout to load.
      def self.load_layout(keyboard_layout)
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
      def self.load_x11_layout(keyboard_layout)
        output = Cheetah.run("/usr/sbin/xkbctrl", keyboard_layout.code, stdout: :capture)
        arguments = get_value_from_output(output, "\"Apply\"").tr("\"", "")
        setxkbmap_array_arguments = arguments.split.unshift("setxkbmap")
        Cheetah.run(setxkbmap_array_arguments)
      end

      def self.get_value_from_output(output, property_name)
        output.lines.map(&:strip).find { |x| x.start_with?(property_name) }.split(":", 2).last
      end

      private_class_method :get_value_from_output, :load_x11_layout
    end
  end

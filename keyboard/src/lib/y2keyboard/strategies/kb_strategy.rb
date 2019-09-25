# Copyright (c) [2019] SUSE LLC
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
    # Class to deal with xkb and kbd keyboard configuration management.
    # Use this class only for temporary changes like changing keyboard
    # layout "on the fly" for example in the inst-sys.
    #
    # Use the systemd strategy for making keyboard changes permanent on
    # the installed system.
    # 
    class KbStrategy
      include Yast::Logger
      
      # Use
      # @param keyboard_code [String] the keyboard layout to set
      # in the running the system (mostly temporary).
      def set_layout(keyboard_code)
        set_x11_layout(keyboard_code) if !Yast::UI.TextMode
        begin
          Yast::Execute.on_target!("loadkeys", keyboard_code) if Yast::UI.TextMode
        rescue Cheetah::ExecutionFailed => e
          log.info(e.message)
          log.info("Error output:    #{e.stderr}")
        end        
      end


    private

      # set x11 keys on the fly.
      # @param keyboard_code [String] the keyboard to set.
      def set_x11_layout(keyboard_code)
        xkbctrl_cmd = "/usr/sbin/xkbctrl"
        if !File.executable?(xkbctrl_cmd)
          log.warn("#{xkbctrl_cmd} not found on system.")
          return
        end
  
        output = Yast::Execute.on_target!(xkbctrl_cmd,
          keyboard_code, stdout: :capture)
          arguments = output.lines.map(&:strip).find { |x| x.start_with?("\"Apply\"") }
        arguments = arguments.split(":", 2).last.tr("\"", "")
        setxkbmap_array_arguments = arguments.split.unshift("setxkbmap")
        Yast::Execute.on_target!(setxkbmap_array_arguments)
      end

    end
  end
end

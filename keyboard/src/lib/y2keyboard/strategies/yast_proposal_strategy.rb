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

Yast.import "Keyboard"

module Y2Keyboard
  module Strategies
    # While the installation or AY-configuration workflow keyboard settings
    # will be handled by the module/Keyboard.rb class. So all get and set calls
    # have to be done over this class.
    class YastProposalStrategy
      # Returns e.b. ["de-latin1-nodeadkeys", "uk", "us",]
      #
      # @return [Array<String>] an array with all available keyboard layouts codes.
      def codes
        Keyboard.codes.keys
      end

      # Apply a new keyboard layout.
      # @param keyboard_code [String] the keyboard layout to apply in the system. E.g. "de-latin1"
      def apply_layout(keyboard_code)
        Keyboard.set(Keyboard.codes[keyboard_code])
      end

      # @return [String] the current key map which has been defined. E.g. "de-latin1"
      def current_layout
        Keyboard.codes.key(Keyboard.current_kbd)
      end
    end
  end
end

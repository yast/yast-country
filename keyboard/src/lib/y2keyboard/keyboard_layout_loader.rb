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
require_relative "strategies/kb_strategy"

module Y2Keyboard
  # Class to change keyboard layout on the fly.
  class KeyboardLayoutLoader

    # Set x11 or virtual console keys on the fly and temporarily.
    # @param keyboard_layout [KeyboardLayout] the keyboard layout to load.
    def self.load_layout(keyboard_layout)
      kb_strategy = Y2Keyboard::Strategies::KbStrategy.new
      kb_strategy.set_layout(keyboard_layout.code)
    end
  end
end

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

require_relative "../dialogs/layout_selector"
require_relative "../strategies/systemd_strategy"

module Y2Keyboard
  module Clients
    # Client with systemd implementation.
    class SystemdKeyboard
      def self.run
        path = File.join(__dir__, "../data/keyboards.yml")
        layout_definitions = YAML.load_file(path)
        systemd_strategy = Y2Keyboard::Strategies::SystemdStrategy.new(layout_definitions)
        Y2Keyboard::Dialogs::LayoutSelector.new(systemd_strategy).run
      end
    end
  end
end

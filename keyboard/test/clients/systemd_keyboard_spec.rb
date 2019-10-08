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

require_relative "../test_helper"
require "y2keyboard/clients/systemd_keyboard"
require "y2keyboard/dialogs/layout_selector"
require "y2keyboard/strategies/systemd_strategy"
require "yaml"
Yast.import "Directory"

describe Y2Keyboard::Clients::SystemdKeyboard do
  describe ".run" do
    let(:dialog) { spy(Y2Keyboard::Dialogs::LayoutSelector) }
    let(:systemd_strategy) { spy(Y2Keyboard::Strategies::SystemdStrategy) }
    subject(:client) { Y2Keyboard::Clients::SystemdKeyboard }

    before do
      allow(Y2Keyboard::Strategies::SystemdStrategy).to receive(:new).and_return(systemd_strategy)
      allow(Y2Keyboard::Dialogs::LayoutSelector).to receive(:new).and_return(dialog)
    end

    it "load keyboard layouts definitions from data directory" do
      expect(Y2Keyboard::KeyboardLayout).to receive(:use).with(anything, Keyboards.all_keyboards)

      client.run
    end

    it "use systemd strategy" do
      expect(Y2Keyboard::KeyboardLayout).to receive(:use).with(systemd_strategy, anything)

      client.run
    end

    it "starts a dialog" do
      expect(Y2Keyboard::Dialogs::LayoutSelector).to receive(:new).and_return(dialog)

      client.run
    end
  end
end
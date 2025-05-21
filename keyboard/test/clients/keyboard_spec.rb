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
require "y2keyboard/clients/keyboard"
require "y2keyboard/dialogs/layout_selector"
require "y2keyboard/strategies/systemd_strategy"

Yast.import "Directory"
Yast.import "Package"

describe Yast::KeyboardClient do
  describe ".setup" do
    let(:dialog) { spy(Y2Keyboard::Dialogs::LayoutSelector) }
    let(:systemd_strategy) { spy(Y2Keyboard::Strategies::SystemdStrategy) }
    let(:yast_proposal_strategy) { spy(Y2Keyboard::Strategies::YastProposalStrategy) }
    subject(:client) { Yast::KeyboardClient }

    before do
      allow(Y2Keyboard::Strategies::SystemdStrategy).to receive(:new).and_return(systemd_strategy)
      allow(Y2Keyboard::Strategies::YastProposalStrategy).to receive(:new).and_return(yast_proposal_strategy)
      allow(Y2Keyboard::Dialogs::LayoutSelector).to receive(:new).and_return(dialog)
      allow(Yast::Package).to receive(:InstallAll).with(["setxkbmap"]).and_return(true)
    end

    it "load keyboard layouts definitions from data directory" do
      expect(Y2Keyboard::KeyboardLayout).to receive(:use).with(anything, Keyboards.all_keyboards)

      client.setup
    end

    it "use systemd strategy in a running system" do
      allow(Yast::Stage).to receive(:initial).and_return false
      expect(Y2Keyboard::KeyboardLayout).to receive(:use).with(systemd_strategy, anything)

      client.setup
    end

    it "use yast_proposal_strategy strategy while installation" do
      allow(Yast::Stage).to receive(:initial).and_return true
      expect(Y2Keyboard::KeyboardLayout).to receive(:use).with(yast_proposal_strategy, anything)

      client.setup
    end

    it "use yast_proposal_strategy strategy in the AY configuration module" do
      allow(Yast::Stage).to receive(:initial).and_return false
      allow(Yast::Mode).to receive(:config).and_return true
      expect(Y2Keyboard::KeyboardLayout).to receive(:use).with(yast_proposal_strategy, anything)

      client.setup
    end

    it "starts a dialog" do
      expect(Y2Keyboard::Dialogs::LayoutSelector).to receive(:new).and_return(dialog)

      client.setup
    end
  end
end

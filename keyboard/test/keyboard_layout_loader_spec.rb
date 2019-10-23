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

require_relative "test_helper"
require "y2keyboard/keyboard_layout"
require "y2keyboard/keyboard_layout_loader"
require "y2keyboard/strategies/kb_strategy"
require "yast"

Yast.import "UI"

describe Y2Keyboard::KeyboardLayoutLoader do
  subject(:layout_loader) { Y2Keyboard::KeyboardLayoutLoader }

  describe "#load_layout" do
    let(:new_layout) {Y2Keyboard::KeyboardLayout.new("es", "Spanish")}

    it "set layout temporarily" do
      expect_any_instance_of(Y2Keyboard::Strategies::KbStrategy).to receive(:set_layout).with(new_layout.code)

      layout_loader.load_layout(new_layout)
    end
  end
end

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
require "y2keyboard/dialogs/layout_selector"
require "y2keyboard/strategies/systemd_strategy"

describe Y2Keyboard::Dialogs::LayoutSelector do
  english = Y2Keyboard::KeyboardLayout.new("en", "English")
  spanish = Y2Keyboard::KeyboardLayout.new("es", "Spanish")
  layouts = [english, spanish]
  let(:strategy) { Y2Keyboard::Strategies::SystemdStrategy.new(layout_definitions) }
  subject(:layout_selector) { Y2Keyboard::Dialogs::LayoutSelector.new(strategy) }

  before do
    allow(Yast::UI).to receive(:OpenDialog).and_return(true)
    allow(Yast::UI).to receive(:CloseDialog).and_return(true)
    allow(strategy).to receive(:load_layout)
    allow(strategy).to receive(:current_layout).and_return(english)
    allow(strategy).to receive(:all).and_return(layouts)
  end

  describe "#run" do
    before do
      mock_ui_events(:cancel)
    end

    it "retrieve keyboard layouts from strategy" do
      expect(strategy).to receive(:all)

      layout_selector.run
    end

    it "lists the keyboard layouts" do
      allow(strategy).to receive(:all).and_return(layouts)

      expect_display_layouts(layouts)

      layout_selector.run
    end

    it "select the current layout in the list" do
      allow(strategy).to receive(:all).and_return(layouts)
      allow(strategy).to receive(:current_layout).and_return(english)

      expect_create_list_with_current_layout(english)

      layout_selector.run
    end
  end

  describe "#accept_handler" do
    before do
      mock_ui_events(:accept)
    end

    it "change the keymap to the selected layout" do
      selecting_layout_from_list(spanish)

      expect(strategy).to receive(:apply_layout).with(spanish)

      layout_selector.run
    end

    it "closes the dialog" do
      selecting_layout_from_list(spanish)
      allow(strategy).to receive(:apply_layout)

      expect(layout_selector).to receive(:finish_dialog).and_call_original

      layout_selector.run
    end
  end

  describe "#layout_list_handler" do
    before do
      mock_ui_events(:layout_list, :cancel)
    end

    it "change the keymap to the selected layout" do
      selecting_layout_from_list(spanish)

      expect(strategy).to receive(:load_layout).with(spanish)

      layout_selector.run
    end
  end

  describe "#cancel_handler" do
    before do
      mock_ui_events(:cancel)
    end

    it "closes the dialog" do
      expect(layout_selector).to receive(:finish_dialog).and_call_original

      layout_selector.run
    end

    it "restores the keyboard layout to the previous selected" do
      allow(strategy).to receive(:current_layout).and_return(english)

      expect(strategy).to receive(:load_layout).with(english)

      layout_selector.run
    end
  end
end

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
require "y2keyboard/dialogs/layout_selector"

describe Y2Keyboard::Dialogs::LayoutSelector do
  english = Y2Keyboard::KeyboardLayout.new("en", "English")
  spanish = Y2Keyboard::KeyboardLayout.new("es", "Spanish")
  layouts = [english, spanish]
  let(:keyboard_layout) { Y2Keyboard::KeyboardLayout }
  subject(:layout_selector) { Y2Keyboard::Dialogs::LayoutSelector.new }

  before do
    allow(Yast::UI).to receive(:OpenDialog).and_return(true)
    allow(Yast::UI).to receive(:CloseDialog).and_return(true)
    allow(Y2Keyboard::KeyboardLayout).to receive(:current_layout).and_return(english)
    allow(Y2Keyboard::KeyboardLayout).to receive(:all).and_return(layouts)
  end

  describe "#run" do
    before do
      mock_ui_events(:cancel)
    end

    context "in firstboot" do
      before do
        allow(Yast::Stage).to receive(:firstboot).and_return(true)
      end

      it "sets wizard content" do
        expect(Yast::Wizard).to receive(:SetContents)
        expect(Yast::UI).to_not receive(:OpenDialog)

        layout_selector.run
      end

      it "does not close dialog" do
        expect(Yast::UI).to_not receive(:CloseDialog)

        layout_selector.run
      end
    end

    context "in normal mode" do
      before do
        allow(Yast::Stage).to receive(:firstboot).and_return(false)
      end

      it "opens dialog" do
        expect(Yast::UI).to receive(:OpenDialog).and_return(true)

        layout_selector.run
      end

      it "closes dialog" do
        expect(Yast::UI).to receive(:CloseDialog).and_return(true)

        layout_selector.run
      end
    end

    it "retrieve keyboard layouts" do
      expect(keyboard_layout).to receive(:all)

      layout_selector.run
    end

    it "lists the keyboard layouts" do
      allow(keyboard_layout).to receive(:all).and_return(layouts)

      expect_display_layouts(layouts)

      layout_selector.run
    end

    it "select the current layout in the list" do
      allow(keyboard_layout).to receive(:all).and_return(layouts)
      allow(keyboard_layout).to receive(:current_layout).and_return(english)

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

      expect(spanish).to receive(:apply_layout)

      layout_selector.run
    end

    it "closes the dialog" do
      selecting_layout_from_list(spanish)
      allow(spanish).to receive(:apply_layout)

      expect(layout_selector).to receive(:finish_dialog).and_call_original

      layout_selector.run
    end
  end

  describe "#layout_list_handler" do
    before do
      mock_ui_events(:layout_list, :cancel)
      allow(Y2Keyboard::KeyboardLayoutLoader).to receive(:load_layout).with(english)
    end

    it "change the keymap to the selected layout" do
      selecting_layout_from_list(spanish)

      expect(Y2Keyboard::KeyboardLayoutLoader).to receive(:load_layout).with(spanish)

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
      allow(keyboard_layout).to receive(:current_layout).and_return(english)

      expect(Y2Keyboard::KeyboardLayoutLoader).to receive(:load_layout).with(english)

      layout_selector.run
    end
  end
end

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
require "y2keyboard/strategies/systemd_strategy"
require "yast"

Yast.import "UI"

describe Y2Keyboard::Strategies::SystemdStrategy do
  subject(:systemd_strategy) { Y2Keyboard::Strategies::SystemdStrategy.new }

  describe "#codes" do
    subject(:layout_codes) { systemd_strategy.codes }

    it "returns a lists of available layout codes" do
      expected_layouts = ["es", "fr-latin1", "us"]
      given_layouts(expected_layouts)

      expect(layout_codes).to be_an(Array)
      expect(layout_codes).to all(be_an(String))
      expect(layout_codes).to match_array(expected_layouts)
    end
  end

  describe "#apply_layout" do
    context "valid keyboard code" do
      it "changes the keyboard layout" do
        new_layout = Y2Keyboard::KeyboardLayout.new("es", "Spanish")
        expect(Yast::Execute).to receive(:on_target!).with(
          "localectl", "set-keymap", new_layout.code
        )

        systemd_strategy.apply_layout(new_layout.code)
      end
    end

    context "empty keyboard code" do
      it "does not try to set the keyboard layout" do
        expect(Yast::Execute).not_to receive(:on_target!).with(
          "localectl", "set-keymap", anything)
        systemd_strategy.apply_layout("")
      end
    end
  end

  describe "#current_layout" do
    it "returns the current used keyboard layout code" do
      current_selected_layout_code = "gb"
      given_layouts(["es", current_selected_layout_code, "us"])
      given_a_current_layout(current_selected_layout_code)

      expect(systemd_strategy.current_layout).to be_an(String)
      expect(systemd_strategy.current_layout).to eq(current_selected_layout_code)
    end
  end
end

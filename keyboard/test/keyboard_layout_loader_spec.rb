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
require "y2keyboard/strategies/systemd_strategy"
require "yast"

Yast.import "UI"

describe Y2Keyboard::KeyboardLayoutLoader do
  subject(:systemd_strategy) { Y2Keyboard::KeyboardLayoutLoader }

  describe "#load_layout" do
    new_layout = Y2Keyboard::KeyboardLayout.new("es", "Spanish")
    arguments_to_apply = "-layout es -model microsoftpro -option terminate:ctrl_alt_bksp"
    expected_arguments = [
      "setxkbmap",
      "-layout",
      "es",
      "-model",
      "microsoftpro",
      "-option",
      "terminate:ctrl_alt_bksp"
    ]

    describe "in X server" do
      before do
        allow(Yast::UI).to receive(:TextMode).and_return(false)
      end

      it "changes the current keyboard layout used in xorg" do
        given_keyboard_configuration(new_layout.code, arguments_to_apply)
        expect(Yast::Execute).to receive(:on_target!).with(expected_arguments)

        systemd_strategy.load_layout(new_layout)
      end

      it "do not try to change the current keyboard layout in console" do
        given_keyboard_configuration(new_layout.code, expected_arguments)
        expect(Yast::Execute).not_to receive(:on_target!).with("loadkeys", new_layout.code)

        systemd_strategy.load_layout(new_layout)
      end
    end

    describe "in text mode" do
      before do
        allow(Yast::UI).to receive(:TextMode).and_return(true)
      end

      it "do not try to change the current keyboard layout in xorg" do
        expect(Yast::Execute).not_to receive(:on_target!).with("setxkbmap", new_layout.code)

        systemd_strategy.load_layout(new_layout)
      end

      it "changes the current keyboard layout in console" do
        expect(Yast::Execute).to receive(:on_target!).with("loadkeys", new_layout.code)

        systemd_strategy.load_layout(new_layout)
      end
    end

    describe "using ncurses inside X server" do
      before do
        allow(Yast::UI).to receive(:TextMode).and_return(true)
      end

      describe "when setting current keyboard layout in console" do
        # This tests describes the case when running the module in text mode inside a X server.
        # In that case, when trying to execute 'loadkeys' it will fail due to it should't
        # be execute from X server.
        it "do not raise error" do
          allow(Yast::Execute).to receive(:on_target!)
            .with("loadkeys", new_layout.code)
            .and_raise(loadkeys_error)

          expect { systemd_strategy.load_layout(new_layout) }.not_to raise_error
        end

        it "log error information" do
          error = loadkeys_error
          allow(Yast::Execute).to receive(:on_target!)
            .with("loadkeys", new_layout.code)
            .and_raise(error)

          expect(Y2Keyboard::KeyboardLayoutLoader.log).to receive(:info)
            .with(error.message)
          expect(Y2Keyboard::KeyboardLayoutLoader.log).to receive(:info)
            .with("Error output:    #{error.stderr}")

          systemd_strategy.load_layout(new_layout)
        end
      end
    end
  end
end

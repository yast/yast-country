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

# Spec helper for keyboard module tests
module KeyboardSpecHelper
  def mock_ui_events(*events)
    allow(Yast::UI).to receive(:UserInput).and_return(*events)
  end

  def given_layouts(layouts_to_return)
    allow(Cheetah).to receive(:run).with(
      "localectl", "list-keymaps", stdout: :capture
    ).and_return(layouts_to_return.join("\n"))
  end

  def given_a_current_layout(code)
    allow(Cheetah).to receive(:run)
      .with("localectl", "status", stdout: :capture)
      .and_return(
        "   System Locale: LANG=en_US.UTF-8\n" \
        "       VC Keymap: #{code}\n" \
        "       X11 Layout: #{code}\n" \
        "       X11 Model: microsoftpro\n" \
        "       X11 Options: terminate:ctrl_alt_bksp\n"
      )
  end

  def given_a_strategy_with_codes(available_layout_codes)
    double(Y2Keyboard::Strategies::SystemdStrategy, codes: available_layout_codes)
  end

  def layout_definitions
    [
      { "description" => "English (US)", "code" => "us" },
      { "description" => "English (UK)", "code" => "uk" },
      { "description" => "French", "code" => "fr-latin1" },
      { "description" => "Spanish", "code" => "es" }
    ]
  end

  def layout_and_definition_matchs(layout, definition)
    layout.code == definition["code"] && layout.description == definition["description"]
  end

  def selecting_layout_from_list(layout)
    allow(Yast::UI).to receive(:QueryWidget)
      .with(:layout_list, :CurrentItem)
      .and_return(layout.code)
  end

  def loadkeys_error
    Cheetah::ExecutionFailed.new(
      "loadkeys es",
      "Execution of \"loadkeys es\" failed with status 1: " \
      "Couldn't get a file descriptor referring to the console.",
      "",
      "Couldn't get a file descriptor referring to the console"
    )
  end

  def expect_display_layouts(layouts)
    allow(Yast::Term).to receive(:new).and_call_original
    layouts.each do |layout|
      expect(Yast::Term).to receive(:new).with(
        :item,
        Id(layout.code),
        layout.description,
        boolean
      )
    end
  end

  def expect_create_list_with_current_layout(layout)
    allow(Yast::Term).to receive(:new).and_call_original
    expect(Yast::Term).to receive(:new).with(
      :item,
      Id(layout.code),
      layout.description,
      true
    )
  end

  def given_keyboard_configuration(layout_code, arguments)
    allow(Cheetah).to receive(:run).with("/usr/sbin/xkbctrl", layout_code, stdout: :capture)
      .and_return(
        "$[\n" \
          "\"XkbLayout\"    : \"es\",\n" \
          "\"XkbModel\"     : \"microsoftpro\",\n" \
          "\"XkbOptions\"   : \"terminate:ctrl_alt_bksp\",\n" \
          "\"Apply\"        : \"#{arguments}\"\n" \
        "]"
      )
  end
end

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

require "yast"
require "ui/dialog"
require_relative "../keyboard_layout_loader"
require_relative "../keyboard_layout"

Yast.import "UI"
Yast.import "Popup"
Yast.import "Mode"

module Y2Keyboard
  module Dialogs
    # Main dialog where the layouts are listed and can be selected.
    class LayoutSelector < UI::Dialog
      def initialize
        textdomain "country"
        @keyboard_layouts = KeyboardLayout.all
        @previous_selected_layout = KeyboardLayout.current_layout
      end

      def dialog_options
        Opt(:decorated, :defaultsize)
      end

      def dialog_content
        VBox(
          HBox(
            HWeight(20, HStretch()),
            HWeight(50, layout_selection_box),
            HWeight(20, HStretch())
          ),
          footer
        )
      end

      def layout_selection_box
        VBox(
          Left(Heading(_("System Keyboard Configuration"))),
          SelectionBox(
            Id(:layout_list),
            Opt(:notify),
            _("&Keyboard Layout"),
            map_layout_items
          ),
          Yast::Mode.config ? HBox() : InputField(Opt(:hstretch), _("&Test"))
        )
      end

      def map_layout_items
        @keyboard_layouts.map do |layout|
          Item(
            Id(layout.code),
            layout.description,
            layout.code == @previous_selected_layout.code
          )
        end
      end

      def accept_handler
        selected_layout.apply_layout
        finish_dialog(:accept)
      end

      def cancel_handler
        if !Yast::Mode.config # not in AY configuration module
          KeyboardLayoutLoader.load_layout(@previous_selected_layout)
        end
        finish_dialog(:abort)
      end

      def layout_list_handler
        if !Yast::Mode.config # not in AY configuration module
          KeyboardLayoutLoader.load_layout(selected_layout)
        end
      end

      def selected_layout
        selected = Yast::UI.QueryWidget(:layout_list, :CurrentItem)
        @keyboard_layouts.find { |x| x.code == selected }
      end

      def help_handler
        Yast::Popup.LongText(
          _("Help"),
          RichText(help_text),
          40,
          20
        )
      end

      # Text to display when the help button is pressed
      #
      # @return [String]
      def help_text
        # TRANSLATORS: help text
        _("\n<p><big><b>Keyboard Configuration</b></big></p>" \
          "<p>\nChoose the <b>Keyboard Layout</b> to use for " \
          "installation and in the installed system.<br>" \
          "Test the layout in <b>Test</b>.</p>")
      end

      def footer
        HBox(
          HSpacing(),
          Left(PushButton(Id(:help), Opt(:key_F1, :help), Yast::Label.HelpButton)),
          PushButton(Id(:cancel), Yast::Label.CancelButton),
          PushButton(Id(:accept), Yast::Label.AcceptButton),
          HSpacing()
        )
      end
    end
  end
end

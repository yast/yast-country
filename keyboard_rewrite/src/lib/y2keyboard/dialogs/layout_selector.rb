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

Yast.import "UI"
Yast.import "Popup"

module Y2Keyboard
  module Dialogs
    # Main dialog where the layouts are listed and can be selected.
    class LayoutSelector < UI::Dialog
      def initialize(strategy)
        textdomain "country"
        @keyboard_layouts = strategy.all
        @previous_selected_layout = strategy.current_layout
        @strategy = strategy
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
          SelectionBox(
            Id(:layout_list),
            Opt(:notify),
            _("&Keyboard Layout"),
            map_layout_items
          ),
          InputField(Opt(:hstretch), _("&Test"))
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
        @strategy.apply_layout(selected_layout)
        finish_dialog
      end

      def cancel_handler
        KeyboardLayoutLoader.load_layout(@previous_selected_layout)
        finish_dialog
      end

      def layout_list_handler
        KeyboardLayoutLoader.load_layout(selected_layout)
      end

      def selected_layout
        selected = Yast::UI.QueryWidget(:layout_list, :CurrentItem)
        @keyboard_layouts.find { |x| x.code == selected }
      end

      def footer
        HBox(
          HSpacing(),
          PushButton(Id(:cancel), Yast::Label.CancelButton),
          PushButton(Id(:accept), Yast::Label.AcceptButton),
          HSpacing()
        )
      end
    end
  end
end

require "yast"
require "ui/dialog"
require_relative "../keyboard_layout"

Yast.import "UI"
Yast.import "Popup"

module Y2Keyboard
  module Dialogs
    class LayoutSelector < UI::Dialog

      def initialize(keyboard_layouts)
        textdomain "country"
        @keyboard_layouts = keyboard_layouts
      end

      def dialog_options
        Opt(:decorated, :defaultsize)
      end

      def dialog_content
        VBox(
          SelectionBox(
            Id(:layout_lists),
            Opt(:notify),
            _("&Keyboard Layout"),
            @keyboard_layouts.map(&:description)
            ),
          footer
        )
      end

      def accept_handler
        Y2Keyboard::KeyboardLayout.set_layout(selected_layout)
        finish_dialog
      end

      def layout_lists_handler
        Y2Keyboard::KeyboardLayout.set_current_layout(selected_layout)
      end

      def selected_layout
        selected_layout = Yast::UI.QueryWidget(:layout_lists, :CurrentItem)
        @keyboard_layouts.find { |x| x.description == selected_layout }
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

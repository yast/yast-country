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
        @previous_selected_layout = Y2Keyboard::KeyboardLayout.get_current_layout()
      end

      def dialog_options
        Opt(:decorated, :defaultsize)
      end

      def dialog_content
        VBox(
          SelectionBox(
            Id(:layout_list),
            Opt(:notify),
            _("&Keyboard Layout"),
            @keyboard_layouts.map(&:description)
            ),
            InputField(Opt(:hstretch), _("&Test")),
          footer
        )
      end

      def accept_handler
        Y2Keyboard::KeyboardLayout.set_layout(selected_layout)
        finish_dialog
      end

      def cancel_handler
        Y2Keyboard::KeyboardLayout.load_layout(@previous_selected_layout)
        finish_dialog
      end

      def layout_list_handler
        Y2Keyboard::KeyboardLayout.load_layout(selected_layout)
      end

      def selected_layout
        selected = Yast::UI.QueryWidget(:layout_list, :CurrentItem)
        @keyboard_layouts.find { |x| x.description == selected }
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

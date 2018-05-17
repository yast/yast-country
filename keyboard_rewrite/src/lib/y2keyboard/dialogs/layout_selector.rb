require "yast"
require "ui/dialog"
require_relative "../keyboard_layout"

Yast.import "UI"
Yast.import "Popup"

module Y2Keyboard
  module Dialogs
    # Main dialog where the layouts are listed and can change the keyboard layout
    class LayoutSelector < UI::Dialog
      def initialize(keyboard_layouts, strategy)
        textdomain "country"
        @keyboard_layouts = keyboard_layouts
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
            @keyboard_layouts.map(&:description)
          ),
          InputField(Opt(:hstretch), _("&Test"))
        )
      end

      def accept_handler
        @strategy.apply_layout(selected_layout)
        finish_dialog
      end

      def cancel_handler
        @strategy.load_layout(@previous_selected_layout)
        finish_dialog
      end

      def layout_list_handler
        @strategy.load_layout(selected_layout)
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

require "yast"
require "ui/dialog"
require "y2_keyboard/keyboard_layout_repository"

Yast.import "UI"
Yast.import "Popup"

module Y2Keyboard
  module Dialog
    class LayoutSelector < UI::Dialog

      def dialog_options
        Opt(:decorated, :defaultsize)
      end

      def dialog_content
        VBox(
          SelectionBox(_("&Keyboard Layout"), Y2Keyboard::KeyboardLayoutRepository.load),
          footer
        )
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
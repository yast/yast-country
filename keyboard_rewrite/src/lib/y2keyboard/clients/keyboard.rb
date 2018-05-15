require_relative "../dialogs/layout_selector"

module Y2Keyboard
  module Clients
    class Keyboard
      def self.run
        layouts = Y2Keyboard::KeyboardLayout.all
        Y2Keyboard::Dialogs::LayoutSelector.new(layouts).run
      end
    end
  end
end

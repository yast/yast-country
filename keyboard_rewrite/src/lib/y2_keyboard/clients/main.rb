require_relative "../dialogs/layout_selector"

module Y2Keyboard
  module Clients
    class Main
      def self.run
        Y2Keyboard::Dialogs::LayoutSelector.run
      end
    end
  end
end




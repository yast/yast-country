require_relative "../dialogs/layout_selector"
require_relative "../strategies/systemd_strategy"

module Y2Keyboard
  module Clients
    # Simple client to run LayoutSelector.
    class Keyboard
      def self.run
        systemdStrategy = Y2Keyboard::Strategies::SystemdStrategy.new
        Y2Keyboard::Dialogs::LayoutSelector.new(systemdStrategy).run
      end
    end
  end
end

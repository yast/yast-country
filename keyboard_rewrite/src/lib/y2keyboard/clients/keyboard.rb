require_relative "../dialogs/layout_selector"
require_relative "../strategies/systemd_strategy"

module Y2Keyboard
  module Clients
    # Simple client to run LayoutSelector.
    class Keyboard
      def self.run
        systemdStrategy = Y2Keyboard::Strategies::SystemdStrategy.new
        layouts = systemdStrategy.all
        Y2Keyboard::Dialogs::LayoutSelector.new(layouts, systemdStrategy).run
      end
    end
  end
end

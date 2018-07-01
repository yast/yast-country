require_relative "../dialogs/layout_selector"
require_relative "../strategies/systemd_strategy"

module Y2Keyboard
  module Clients
    # Simple client to run LayoutSelector.
    class SystemdKeyboard
      def self.run
        path = File.join(__dir__, "../data/keyboards.yml")
        layout_definitions = YAML.load_file(path)
        systemd_strategy = Y2Keyboard::Strategies::SystemdStrategy.new(layout_definitions)
        Y2Keyboard::Dialogs::LayoutSelector.new(systemd_strategy).run
      end
    end
  end
end

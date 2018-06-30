require_relative "../test_helper"
require "y2keyboard/clients/systemd_keyboard"
require "y2keyboard/dialogs/layout_selector"
require "y2keyboard/strategies/systemd_strategy"

describe Y2Keyboard::Clients::SystemdKeyboard do
  describe ".run" do
    it "starts a dialog with systemd implementation" do
      dialog = spy(Y2Keyboard::Dialogs::LayoutSelector)
      strategy = spy(Y2Keyboard::Strategies::SystemdStrategy)
      allow(Y2Keyboard::Strategies::SystemdStrategy).to receive(:new).and_return(strategy)
      expect(Y2Keyboard::Dialogs::LayoutSelector).to receive(:new).with(strategy).and_return(dialog)

      Y2Keyboard::Clients::SystemdKeyboard.run
    end
  end
end

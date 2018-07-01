require_relative "../test_helper"
require "y2keyboard/clients/systemd_keyboard"
require "y2keyboard/dialogs/layout_selector"
require "y2keyboard/strategies/systemd_strategy"

describe Y2Keyboard::Clients::SystemdKeyboard do
  describe ".run" do
    let(:dialog) { spy(Y2Keyboard::Dialogs::LayoutSelector) }
    let(:strategy) { spy(Y2Keyboard::Strategies::SystemdStrategy) }
    subject(:client) { Y2Keyboard::Clients::SystemdKeyboard }

    before do
      allow(Y2Keyboard::Strategies::SystemdStrategy).to receive(:new).and_return(strategy)
      allow(Y2Keyboard::Dialogs::LayoutSelector).to receive(:new).with(strategy).and_return(dialog)
    end

    it "load keyboard layouts file settings" do
      expected_path = "path/to/keyboard.yml"
      layouts_data = {"us"=>{"description"=>"English (US)"}, "uk"=>{"description"=>"English (UK)"}}
      allow(File).to receive(:join).with(anything, "../data/keyboards.yml").and_return(expected_path)

      expect(YAML).to receive(:load_file).with(expected_path).and_return(layouts_data)
      expect(Y2Keyboard::Strategies::SystemdStrategy).to receive(:new).with(layouts_data).and_return(strategy)

      client.run
    end

    it "starts a dialog with systemd implementation" do
      expect(Y2Keyboard::Dialogs::LayoutSelector).to receive(:new).with(strategy).and_return(dialog)

      client.run
    end
  end
end

require_relative "test_helper"
require "y2keyboard/keyboard_layout"
require "y2keyboard/dialogs/layout_selector"
require "y2keyboard/strategies/systemd_strategy"

describe Y2Keyboard::Dialogs::LayoutSelector do
  english = Y2Keyboard::KeyboardLayout.new("en", "English")
  spanish = Y2Keyboard::KeyboardLayout.new("es", "Spanish")
  layouts = [english, spanish]
  strategy = Y2Keyboard::Strategies::SystemdStrategy.new
  subject(:layout_selector) { Y2Keyboard::Dialogs::LayoutSelector.new(layouts, strategy) }

  before do
    allow(Yast::UI).to receive(:OpenDialog).and_return(true)
    allow(Yast::UI).to receive(:CloseDialog).and_return(true)
    allow(strategy).to receive(:load_layout)
    allow(strategy).to receive(:current_layout).and_return(english)
  end

  describe "#run" do
    before do
      mock_ui_events(:cancel)
    end

    it "lists the keyboard layouts" do
      expect(english).to receive(:description)
      expect(spanish).to receive(:description)

      layout_selector.run
    end
  end

  describe "#accept_handler" do
    before do
      mock_ui_events(:accept)
    end

    it "change the keymap to the selected layout" do
      selecting_layout_from_list(spanish)

      expect(strategy).to receive(:apply_layout).with(spanish)

      layout_selector.run
    end

    it "closes the dialog" do
      selecting_layout_from_list(spanish)
      allow(strategy).to receive(:apply_layout)

      expect(layout_selector).to receive(:finish_dialog).and_call_original

      layout_selector.run
    end
  end

  describe "#layout_list_handler" do
    before do
      mock_ui_events(:layout_list, :cancel)
    end

    it "change the keymap to the selected layout" do
      selecting_layout_from_list(spanish)

      expect(strategy).to receive(:load_layout).with(spanish)

      layout_selector.run
    end
  end

  describe "#cancel_handler" do
    before do
      mock_ui_events(:cancel)
    end

    it "closes the dialog" do
      expect(layout_selector).to receive(:finish_dialog).and_call_original

      layout_selector.run
    end

    it "restores the keyboard layout to the previous selected" do
      allow(strategy).to receive(:current_layout).and_return(english)

      expect(strategy).to receive(:load_layout).with(english)

      layout_selector.run
    end
  end
end

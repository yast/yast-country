require_relative "test_helper"
require "y2_keyboard/keyboard_layout"
require "y2_keyboard/dialog/layout_selector"

describe Y2Keyboard::Dialog::LayoutSelector do
  subject(:layout_selector) { Y2Keyboard::Dialog::LayoutSelector.new }

  before do
    allow(Yast::UI).to receive(:OpenDialog).and_return(true)
    allow(Yast::UI).to receive(:CloseDialog).and_return(true)
  end

  describe "#run" do
    before do
      mock_ui_events(:cancel)
    end

    it "load keyboard layouts" do
      expect(Y2Keyboard::KeyboardLayout).to receive(:load)
        .and_return([Y2Keyboard::KeyboardLayout.new("en", "English")])
      layout_selector.run
    end
  end

  describe "#accept_handler" do
    before do
      mock_ui_events(:accept)      
    end

    it "change the keymap to the selected layout" do
      allow(Yast::UI).to receive(:QueryWidget)
        .with(:layout_list, :current_item)
        .and_return("es")
      
      expect(Y2Keyboard::KeyboardLayout).to receive(:set_layout).with("es")
      
      layout_selector.run
    end

    it "closes the dialog" do
      expect(layout_selector).to receive(:finish_dialog).and_call_original
      layout_selector.run
    end
  end
end

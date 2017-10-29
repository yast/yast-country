require_relative "test_helper"
require "y2_keyboard/keyboard_layout"
require "y2_keyboard/dialogs/layout_selector"

describe Y2Keyboard::Dialogs::LayoutSelector do
  subject(:layout_selector) { Y2Keyboard::Dialogs::LayoutSelector }

  before do
    allow(Yast::UI).to receive(:OpenDialog).and_return(true)
    allow(Yast::UI).to receive(:CloseDialog).and_return(true)
  end

  describe "#run" do
    before do
      mock_ui_events(:cancel)
    end

    it "lists the keyboard layouts" do
      english = Y2Keyboard::KeyboardLayout.new("en", "English")
      spanish = Y2Keyboard::KeyboardLayout.new("es", "Spanish")
      layouts = [english, spanish]
      expect(english).to receive(:description)
      expect(spanish).to receive(:description)

      layout_selector.new(layouts).run
    end
  end
end

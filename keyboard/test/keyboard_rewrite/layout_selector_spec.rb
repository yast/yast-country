require_relative "../test_helper"
require "y2_keyboard/keyboard_layout_repository"
require "y2_keyboard/dialog/layout_selector"

describe Y2Keyboard::Dialog::LayoutSelector do
  def mock_ui_events(*events)
    allow(Yast::UI).to receive(:UserInput).and_return(*events)
  end

  subject(:layout_selector) { Y2Keyboard::Dialog::LayoutSelector.new }
  
  before do
    allow(Yast::UI).to receive(:OpenDialog).and_return(true)
    allow(Yast::UI).to receive(:CloseDialog).and_return(true)
  end
  
  describe '#run' do
    before do
      mock_ui_events(:cancel)      
    end

    it 'load keyboard layouts' do
      expect(Y2Keyboard::KeyboardLayoutRepository).to receive(:load)
      layout_selector.run
    end  
  end
end
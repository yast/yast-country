require_relative "./test_helper"
require "y2_keyboard/keyboard_layout_repository"

describe Y2Keyboard::KeyboardLayoutRepository do
  describe 'load keyboard layouts' do
    subject(:load_keyboard_layouts) { Y2Keyboard::KeyboardLayoutRepository.load() }

    it 'returns a lists of keyboard layouts' do
      allow(Cheetah).to receive(:run).with(
        "localectl", "list-x11-keymap-layouts", stdout: :capture
      ).and_return("es\nfr\nus\n")

      expect(load_keyboard_layouts).to eq(["es", "fr", "us"])
    end
  end
end
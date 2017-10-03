require_relative "./test_helper"
require "y2_keyboard/keyboard_layout_repository"

describe Y2Keyboard::KeyboardLayoutRepository do
  describe 'load keyboard layouts' do
    subject(:load_keyboard_layouts) { Y2Keyboard::KeyboardLayoutRepository.load() }

    it 'returns a lists of keyboard layouts' do
      expected_layouts = ["es", "fr", "us"]
      given_layouts(expected_layouts)

      expect(load_keyboard_layouts).to eq(expected_layouts)
    end
  end
end
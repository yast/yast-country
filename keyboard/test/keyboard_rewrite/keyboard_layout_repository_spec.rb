require_relative "./test_helper"
require "y2_keyboard/keyboard_layout_repository"

describe Y2Keyboard::KeyboardLayoutRepository do
  describe 'load keyboard layouts' do
    subject(:load_keyboard_layouts) { Y2Keyboard::KeyboardLayoutRepository.load() }

    it 'returns a lists of keyboard layouts' do
      expected_layouts = ["es", "fr", "us"]
      given_layouts(expected_layouts)

      expect(load_keyboard_layouts).to be_an(Array)
      expect(load_keyboard_layouts).to all(be_an(Y2Keyboard::KeyboardLayout))
      layout_codes_loaded = load_keyboard_layouts.map { |layout| layout.code }
      expect(layout_codes_loaded).to eq(expected_layouts)
    end

    it 'initialize the layout description' do
      layout_list = ["es"]
      given_layouts(layout_list)

      expect(load_keyboard_layouts.first.description).to eq("Spanish")
    end
  end
end
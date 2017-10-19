require_relative "./test_helper"
require "y2_keyboard/keyboard_layout"

describe Y2Keyboard::KeyboardLayout do
  describe ".load" do
    subject(:load_keyboard_layouts) { Y2Keyboard::KeyboardLayout.load }

    it "returns a lists of keyboard layouts" do
      expected_layouts = ["es", "fr", "us"]
      given_layouts(expected_layouts)

      expect(load_keyboard_layouts).to be_an(Array)
      expect(load_keyboard_layouts).to all(be_an(Y2Keyboard::KeyboardLayout))
      layout_codes_loaded = load_keyboard_layouts.map(&:code)
      expect(layout_codes_loaded).to eq(expected_layouts)
    end

    it "initialize the layout description" do
      layout_list = ["es"]
      given_layouts(layout_list)

      expect(load_keyboard_layouts.first.description).to eq("Spanish")
    end

    it "does not returns layouts that not have description" do
      layout_list = ["zz", "es", "aa"]
      given_layouts(layout_list)

      expect(load_keyboard_layouts.count).to be(1)
      expect(load_keyboard_layouts.first.code).to eq("es")
    end
  end

  describe ".set_layout" do
    subject(:keyboard_layout) { Y2Keyboard::KeyboardLayout }
    
    it "set the console layout" do
      new_layout = Y2Keyboard::KeyboardLayout.new("es", "Spanish")
      expect(Cheetah).to receive(:run).with(
        "localectl", "set-keymap", "--no-convert", new_layout.code
      )

      keyboard_layout.set_layout(new_layout)
    end    
  end  
end

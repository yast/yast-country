require_relative "test_helper"
require "y2keyboard/keyboard_layout"

describe Y2Keyboard::KeyboardLayout do
  subject(:keyboard_layout) { Y2Keyboard::KeyboardLayout }

  describe ".all" do
    subject(:load_keyboard_layouts) { Y2Keyboard::KeyboardLayout.all }

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

    it "does not return layouts that does not have description" do
      layout_list = ["zz", "es", "aa"]
      given_layouts(layout_list)

      expect(load_keyboard_layouts.count).to be(1)
      expect(load_keyboard_layouts.first.code).to eq("es")
    end
  end

  describe ".set_layout" do
    it "changes the keyboard layout" do
      new_layout = Y2Keyboard::KeyboardLayout.new("es", "Spanish")
      expect(Cheetah).to receive(:run).with(
        "localectl", "set-keymap", new_layout.code
      )

      keyboard_layout.set_layout(new_layout)
    end
  end

  describe ".load_layout" do
    it "changes the current keyboard layout used in xorg" do
      new_layout = Y2Keyboard::KeyboardLayout.new("es", "Spanish")
      expect(Cheetah).to receive(:run).with("setxkbmap", new_layout.code)

      keyboard_layout.load_layout(new_layout)
    end
  end

  describe ".get_current_layout" do
    it "returns the current used keyboard layout" do
      current_selected_layout_code = "gb"
      given_layouts(["es", current_selected_layout_code, "us"])
      given_a_current_layout(current_selected_layout_code)

      expect(keyboard_layout.get_current_layout()).to be_an(Y2Keyboard::KeyboardLayout)
      expect(keyboard_layout.get_current_layout().code).to eq(current_selected_layout_code)
    end
  end
end

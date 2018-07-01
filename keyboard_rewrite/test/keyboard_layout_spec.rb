require_relative "./test_helper"
require "y2keyboard/keyboard_layout"
require "y2keyboard/strategies/systemd_strategy"

describe Y2Keyboard::KeyboardLayout do
  subject(:keyboard_layout) { Y2Keyboard::KeyboardLayout }

  describe ".all" do
    subject(:all_layouts) { keyboard_layout.all}

    it "returns a lists of keyboard layouts" do
      layout_codes = ["es", "fr-latin1", "us", "uk"]
      strategy = double(Y2Keyboard::Strategies::SystemdStrategy, :codes => layout_codes)
      keyboard_layout.use(strategy)
      keyboard_layout.layout_definitions(layout_definitions)

      expect(all_layouts).to be_an(Array)
      expect(all_layouts).to all(be_an(Y2Keyboard::KeyboardLayout))
    end

    it "only returns layouts that are available" do
      available_layout_codes = ["es", "fr-latin1", "us"]
      strategy = double(Y2Keyboard::Strategies::SystemdStrategy, :codes => available_layout_codes)
      keyboard_layout.use(strategy)
      keyboard_layout.layout_definitions(layout_definitions)

      layout_codes_loaded = all_layouts.map(&:code)
      expect(layout_codes_loaded).to match_array(available_layout_codes)
    end
  end
end

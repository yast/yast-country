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

    it "use layout definitions to create keyboard layout with description" do
      available_layout_codes = ["es", "fr-latin1", "us", "uk"]
      strategy = double(Y2Keyboard::Strategies::SystemdStrategy, :codes => available_layout_codes)
      keyboard_layout.use(strategy)
      keyboard_layout.layout_definitions(layout_definitions)

      layout_definitions.each do |definition|
        expect(all_layouts.any? { |x| layout_and_definition_matchs(x, definition) }).to be_truthy
      end
    end

    it "can return diferent layouts with same code" do
      definitions = [
        {"description"=>"Portuguese (Brazil -- US accents)", "code"=>"us-acentos"},
        {"description"=>"US International", "code"=>"us-acentos"}
      ]
      available_layout_codes = ["us-acentos"]
      strategy = double(Y2Keyboard::Strategies::SystemdStrategy, :codes => available_layout_codes)
      keyboard_layout.use(strategy)
      keyboard_layout.layout_definitions(definitions)

      expect(all_layouts.length).to be(2)
      expect(all_layouts.any? { |x| x.code == "us-acentos" && x.description == "Portuguese (Brazil -- US accents)" })
      expect(all_layouts.any? { |x| x.code == "us-acentos" && x.description == "US International" })
    end
  end
end

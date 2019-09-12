# Copyright (c) [2018] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require_relative "./test_helper"
require "y2keyboard/keyboard_layout"
require "y2keyboard/strategies/systemd_strategy"

describe Y2Keyboard::KeyboardLayout do
  subject(:keyboard_layout) { Y2Keyboard::KeyboardLayout }

  describe ".all" do
    subject(:all_layouts) { keyboard_layout.all }

    it "returns a lists of keyboard layouts" do
      layout_codes = ["es", "fr-latin1", "us", "uk"]
      set_up_keyboard_layout_with(layout_codes, layout_definitions)

      expect(all_layouts).to be_an(Array)
      expect(all_layouts).to all(be_an(Y2Keyboard::KeyboardLayout))
    end

    it "only returns layouts that are available" do
      available_layout_codes = ["es", "fr-latin1", "us"]
      set_up_keyboard_layout_with(available_layout_codes, layout_definitions)

      layout_codes_loaded = all_layouts.map(&:code)
      expect(layout_codes_loaded).to match_array(available_layout_codes)
    end

    it "only returns layouts that exists in layout definition list" do
      available_layout_codes = ["es", "at-sundeadkeys"]
      set_up_keyboard_layout_with(available_layout_codes, layout_definitions)

      expect(all_layouts.length).to be(1)
      expect(all_layouts.map(&:code)).not_to include("at-sundeadkeys")
    end

    it "use layout definitions to create keyboard layout with description" do
      available_layout_codes = ["es", "fr-latin1", "us", "uk"]
      set_up_keyboard_layout_with(available_layout_codes, layout_definitions)

      layout_definitions.each do |definition|
        expect(all_layouts.any? { |x| layout_and_definition_matchs(x, definition) }).to be_truthy
      end
    end

    it "can return diferent layouts with same code" do
      brazil_us_accents = "Portuguese (Brazil -- US accents)"
      us_international = "US International"
      definitions = [
        { "description" => brazil_us_accents, "code" => "us-acentos" },
        { "description" => us_international, "code" => "us-acentos" }
      ]
      available_layout_codes = ["us-acentos"]
      set_up_keyboard_layout_with(available_layout_codes, definitions)

      expect(all_layouts.length).to be(2)
      expect(all_layouts.any? { |x| x.code == "us-acentos" && x.description == brazil_us_accents })
      expect(all_layouts.any? { |x| x.code == "us-acentos" && x.description == us_international })
    end
  end

  describe ".current_layout" do
    let(:expected_layout) { Y2Keyboard::KeyboardLayout.new("es", "Spanish") }
    let(:strategy) { spy(Y2Keyboard::Strategies::SystemdStrategy) }

    before(:each) do
      keyboard_layout.use(strategy, layout_definitions)
      allow(strategy).to receive(:current_layout).and_return(expected_layout.code)
    end

    it "return a keyboard layout" do
      expect(keyboard_layout.current_layout).to be_an(Y2Keyboard::KeyboardLayout)
    end

    it "return current layout being used in the system with the appropriate description" do
      expect(keyboard_layout.current_layout.code).to eq(expected_layout.code)
      expect(keyboard_layout.current_layout.description).to eq(expected_layout.description)
    end
  end

  describe "#apply_layout" do
    it "call to apply layout" do
      layout = Y2Keyboard::KeyboardLayout.new("es", "Spanish")
      strategy = spy(Y2Keyboard::Strategies::SystemdStrategy)
      keyboard_layout.use(strategy, layout_definitions)

      expect(strategy).to receive(:apply_layout).with(layout)

      layout.apply_layout
    end
  end

  def set_up_keyboard_layout_with(available_layout_codes, layout_definitions)
    keyboard_layout.use(given_a_strategy_with_codes(available_layout_codes), layout_definitions)
  end
end

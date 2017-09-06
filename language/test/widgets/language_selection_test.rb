#!/usr/bin/env rspec

require_relative "../test_helper"
require "y2country/widgets/language_selection"

describe Y2Country::Widgets::LanguageSelection do

  subject(:widget) { described_class.new }
  let(:default_language) { "en_US" }

  LANGUAGES = [["af_ZA", "Afrikaans - Afrikaans"], ["en_US", "English (US)"]].freeze
  LANGUAGE_ITEMS = LANGUAGES.map do |lang|
    code, description = lang
    Yast::Term.new(:item, Yast::Term.new(:id, code), description)
  end.freeze

  before do
    allow(Yast::Language).to receive(:GetLanguageItems)
    allow(Yast::Language).to receive(:GetLanguageItems)
      .with(:first_screen).and_return(LANGUAGE_ITEMS)
  end

  it "enlists all available languages" do
    expect(widget.items).to eq(LANGUAGES)
  end

  describe "#handle" do
    before do
      allow(Yast::Language).to receive(:language).and_return(default_language)
      allow(widget).to receive(:value).and_return(value)
      allow(Yast::Language).to receive(:Set)
      allow(Yast::Language).to receive(:languages=)
      allow(Yast::Timezone).to receive(:ResetZonemap)
    end

    context "when language remains unchanged" do
      let(:value) { default_language }

      it "returns nil" do
        expect(widget.handle).to eq(nil)
      end
    end

    context "when language has been changed" do
      let(:value) { "af_ZA" }

      it "sets the new language" do
        expect(Yast::Language).to receive(:Set).with(value)
        expect(Yast::Language).to receive(:languages=).with(value)
        widget.handle
      end

      it "resets the timezones map" do
        expect(Yast::Timezone).to receive(:ResetZonemap)
        widget.handle
      end
    end
  end

  describe "#store" do
    it "calls #handle method" do
      expect(widget).to receive(:handle)
      widget.store
    end
  end
end

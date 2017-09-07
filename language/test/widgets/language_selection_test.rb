#!/usr/bin/env rspec --format doc

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

  shared_examples "switch language" do |method|
    before do
      allow(Yast::Language).to receive(:SwitchToEnglishIfNeeded).and_return(false)
      allow(Yast::Console).to receive(:SelectFont)
      allow(Yast::Language).to receive(:language).and_return("cs_CZ")
      # value have to be different otherwise it is skipped
      allow(Yast::Language).to receive(:WfmSetLanguage)
      allow(Yast::Language).to receive(:WfmSetGivenLanguage)
    end

    context "language needed to be switched to English" do
      before do
        allow(Yast::Language).to receive(:SwitchToEnglishIfNeeded).and_return(true)
      end

      it "switch language to english" do
        expect(Yast::Language).to receive(:SwitchToEnglishIfNeeded).and_return(true)

        subject.public_send(method)
      end
    end

    context "language does not need to be switched to English" do
      it "sets console font according to language" do
        expect(Yast::Console).to receive(:SelectFont).with("cs_CZ")

        subject.public_send(method)
      end

      it "sets WFM language according to selected language" do
        expect(Yast::Language).to receive(:WfmSetLanguage)

        subject.public_send(method)
      end

      context "selected langauge is nn_NO" do
        before do
          allow(Yast::Language).to receive(:language).and_return("nn_NO")
        end

        it "it sets WFM language to nb_NO instead" do
          expect(Yast::Language).to receive(:WfmSetGivenLanguage).with("nb_NO")

          subject.public_send(method)
        end
      end
    end
  end

  it "enlists all available languages" do
    expect(widget.items).to eq(LANGUAGES)
  end

  describe "#handle" do
    let(:value) { "en_UK" }

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

    context "when emit_event is set to true and Yast::Mode is not config" do
      subject(:widget) { described_class.new(emit_event: true) }

      include_examples "switch language", :handle

      it "returns :redraw" do
        expect(subject.handle).to eq :redraw
      end
    end
  end

  describe "#store" do
    it "calls #handle method" do
      expect(widget).to receive(:handle)
      widget.store
    end

    context "when emit_event is set to false and Yast::Mode is not config" do
      subject(:widget) { described_class.new(emit_event: false) }

      include_examples "switch language", :store
    end

  end
end

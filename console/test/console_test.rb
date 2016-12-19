#!/usr/bin/env rspec

require_relative "test_helper"

Yast.import "Console"

describe Yast::Console do
  subject(:console) { Yast::Console }

  before { console.main }

  describe "#SelectFont" do
    let(:braille) { false }
    let(:full_language) { "es_ES.UTF-8" }
    let(:language) { "es" }
    let(:product_short_name) { "SLES" }

    before do
      allow(Yast::Linuxrc).to receive(:braille).and_return(braille)
      allow(Yast::Product).to receive(:short_name).and_return(product_short_name)
    end

    it "sets console fonts for the given language" do
      expect(Yast::UI).to receive(:SetConsoleFont)
        .with("(K", "lat9w-16.psfu", "trivial", "", "es")
      console.SelectFont(language)
    end

    it "returns the encoding" do
      expect(console.SelectFont(language)).to eq("UTF-8")
    end

    context "when no console font is available" do
      it "does not set the console font" do
        expect(Yast::UI).to_not receive(:SetConsole)
        console.SelectFont("martian")
      end

      it "returns the encoding" do
        expect(console.SelectFont(language)).to eq("UTF-8")
      end
    end

    context "when using a product with a decidated console map" do
      let(:product_short_name) { "openSUSE" }

      it "sets console fonts for the given language" do
        expect(Yast::UI).to receive(:SetConsoleFont)
          .with("", "eurlatgr.psfu", "none", "", "es")
        console.SelectFont(language)
      end
    end

    context "when using braille" do
      let(:braille) { true }

      it "runs /usr/bin/setfont" do
        expect(Yast::SCR).to receive(:Execute)
          .with(Yast::Path.new(".target.bash"), "/usr/bin/setfont")
        console.SelectFont(language)
      end
    end
  end
end

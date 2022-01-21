#!/usr/bin/env rspec

require_relative "test_helper"
require "y2country/language_dbus"


describe "Yast::Console" do
  subject(:console) { "Yast::Console" }

  before do
    allow(Y2Country).to receive(:read_locale_conf).and_return(nil)
    Yast.import "Console"
    Yast::Console.main
  end

  describe "#SelectFont" do
    let(:braille) { false }
    let(:full_language) { "es_ES.UTF-8" }
    let(:language) { "es_ES" }
    let(:os_release_id) { "sles" }
    # read it from the system, it might be different in Leap and Tumbleweed
    let(:default_encoding) { `LC_CTYPE=#{language} locale charmap`.strip }

    before do
      allow(Yast::Linuxrc).to receive(:braille).and_return(braille)
      allow(Yast::OSRelease).to receive(:id).and_return(os_release_id)
    end

    it "sets console fonts for the given language" do
      expect(Yast::UI).to receive(:SetConsoleFont)
        .with("", "eurlatgr.psfu", "", "", "es_ES")
      Yast::Console.SelectFont(language)
    end

    it "returns the encoding" do
      expect(Yast::Console.SelectFont(language)).to eq(default_encoding)
    end

    context "when no console font is available" do
      it "does not set the console font" do
        expect(Yast::UI).to_not receive(:SetConsoleFont)
        Yast::Console.SelectFont("martian")
      end

      it "returns the encoding" do
        expect(Yast::Console.SelectFont(language)).to eq(default_encoding)
      end
    end

    context "when using a product with a decidated console map" do
      let(:os_release_id) { "opensuse" }

      it "sets console fonts for the given language" do
        expect(Yast::UI).to receive(:SetConsoleFont)
          .with("", "eurlatgr.psfu", "", "", "es_ES")
        Yast::Console.SelectFont(language)
      end
    end

    context "when using braille" do
      let(:braille) { true }

      it "runs /usr/bin/setfont" do
        expect(Yast::SCR).to receive(:Execute)
          .with(Yast::Path.new(".target.bash"), "/usr/bin/setfont")
        Yast::Console.SelectFont(language)
      end
    end
  end
end

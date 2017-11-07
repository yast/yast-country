#!/usr/bin/env rspec
# coding: utf-8

require_relative "test_helper"
require "y2country/language_dbus"


describe "Language" do
  subject { Yast::Language }

  let(:languages_map) {{
    "de_DE" => [
      "Deutsch",
      "Deutsch",
      ".UTF-8",
      "@euro",
      "German"
    ],
    "de_ZU" => [
      "Zulu Deutsch",
      "Zulu Deutsch",
      ".UTF-8",
      ".deZU",
      "Zulu German"
    ],
    "pt_BR" => [
      "Português brasileiro",
      "Portugues brasileiro",
      ".UTF-8",
      "",
      "Portuguese (Brazilian)"
    ],
    # This is a "CJK" language
    "ja_JP" => [
      "日本語",
      "Japanese",
      ".UTF-8",
      ".eucJP",
      "Japanese"
    ]
  }}

  before do
    allow(Y2Country).to receive(:read_locale_conf).and_return(nil)
    Yast.import "Language"
    allow(subject).to receive(:languages_map).and_return(languages_map)
    allow(subject).to receive(:GetLanguagesMap).and_return(languages_map)
  end

  describe "#integrate_inst_sys_extension" do
    let(:new_language) { "de_DE" }

    it "shows UI feedback and extends the inst-sys for selected language" do
      allow(Yast::Popup).to receive(:ShowFeedback)
      allow(Yast::Popup).to receive(:ClearFeedback)
      # There are two or more de_* languages available, so it uses the full language ID
      # instead of using only "de"
      expect(Yast::InstExtensionImage).to receive(:DownloadAndIntegrateExtension).with(/yast2-trans-#{new_language}.*/).and_return(true)
      subject.integrate_inst_sys_extension(new_language)
    end
  end

  describe "#valid_language?" do
    context "when checking for a known, valid language" do
      it "returns true" do
        expect(subject.valid_language?("pt_BR")).to eq(true)
      end
    end

    context "when checking for an unknown language" do
      it "returns false" do
        expect(subject.valid_language?("POSIX")).to eq(false)
      end
    end
  end

  describe "#correct_language" do
    context "when called with a known, valid language" do
      it "returns the same unchanged language" do
        allow(subject).to receive(:valid_language?).with("known_language").and_return(true)

        language = subject.correct_language("known_language")
        expect(language).to eq("known_language")
      end
    end

    context "when called with an unknown language" do
      it "reports an error and returns the default fallback language" do
        allow(subject).to receive(:valid_language?).with("unknown_language").and_return(false)
        expect(Yast::Report).to receive(:Error).with(/unknown_language/)

        language = subject.correct_language("unknown_language")
        expect(language).to eq(Yast::LanguageClass::DEFAULT_FALLBACK_LANGUAGE)
      end

      it "returns the default fallback language without reporting an error if it is disabled " do
        allow(subject).to receive(:valid_language?).with("unknown_language").and_return(false)
        expect(Yast::Report).to_not receive(:Error)

        language = subject.correct_language("unknown_language", error_report: false)
        expect(language).to eq(Yast::LanguageClass::DEFAULT_FALLBACK_LANGUAGE)
      end
    end
  end

  describe "#Set" do
    let(:new_language) { "pt_BR" }
    let(:translated_language_name) { "Português brasileiro" }

    before do
      subject.language = "random_language"

      allow(subject).to receive(:correct_language).and_return(new_language)
      allow(subject).to receive(:GetTextMode).and_return(false)

      expect(Yast::Encoding).to receive(:SetEncLang).with(new_language).and_return(true)
    end

    after do
      # Language uses a constructor that loads several system settings and
      # keeps them in memory
      subject.language = "random_language"
    end

    context "when called in inst-sys" do
      it "sets the new language, encoding integrates inst-sys extension and adapts install.inf" do
        allow(Yast::Stage).to receive(:initial).and_return(true)
        allow(Yast::Mode).to receive(:mode).and_return("installation")
        expect(subject).to receive(:integrate_inst_sys_extension).with(new_language).and_return(nil)
        expect(subject).to receive(:adapt_install_inf).and_return(true)

        subject.Set(new_language)
        expect(subject.GetName).to eq(translated_language_name)
      end
    end

    context "otherwise (running system, AutoYast config, etc.)" do
      it "sets the new language and encoding" do
        allow(Yast::Stage).to receive(:initial).and_return(false)
        allow(Yast::Mode).to receive(:mode).and_return("normal")
        expect(subject).not_to receive(:integrate_inst_sys_extension)
        expect(subject).not_to receive(:adapt_install_inf)

        subject.Set(new_language)
        expect(subject.GetName).to eq(translated_language_name)
      end
    end

    # This is a special case when we start installer in non-CJK language and then switch
    # to a CJK one (CJK == Chinese, Japanese, and Korean), in that case, needed fonts are
    # not loaded and the UI just can't display these CJK characters
    context "when called in text mode, in first stage, and user wants CJK language" do
      let(:new_language) { "ja_JP" }

      it "sets language name into its English translation" do
        allow(Yast::Stage).to receive(:initial).and_return(true)
        allow(Yast::Mode).to receive(:mode).and_return("installation")
        allow(subject).to receive(:GetTextMode).and_return(true)

        subject.Set(new_language)
        expect(subject.GetName).to eq("Japanese")
      end
    end
  end

  describe "#GetLocaleString" do
    context "when using UTF-8" do
      it "returns the full locale" do
        expect(subject.GetLocaleString("de_ZU")).to eq("de_ZU.UTF-8")
      end

      context "and the language is not found in the database" do
        it "returns the full locale" do
          expect(subject.GetLocaleString("ma_MA")).to eq("ma_MA.UTF-8")
        end
      end
    end

    context "and the suffix '@' is already include in the given locale" do
      it "returns the same locale" do
        expect(subject.GetLocaleString("es_ES@euro")).to eq("es_ES@euro")
      end
    end

    context "when UTF-8 is not being used" do
      around do |example|
        subject.SetExpertValues("use_utf8" => false) # disable UTF-8
        example.run
        subject.SetExpertValues("use_utf8" => true) # restore to the default value
      end

      it "returns the full language identifier with no encoding" do
        expect(subject.GetLocaleString("ma_MA")).to eq("ma_MA")
      end
    end
  end
end

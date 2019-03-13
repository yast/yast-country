#!/usr/bin/env rspec
# coding: utf-8

require_relative "test_helper"
require "y2country/language_dbus"

Yast.import "ProductFeatures"
Yast.import "Language"

describe "Yast::Language" do
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

  describe "#Save" do
    let(:readonly) { false }
    let(:language) { "es_ES" }
    let(:initial_stage) { false }
    let(:command_result) { { "exit" => 0 } }

    before do
        allow(Yast::Stage).to receive(:initial).and_return(initial_stage)

        allow(Yast::ProductFeatures).to receive(:GetBooleanFeature)
          .with("globals", "readonly_language")
          .and_return(readonly)

        allow(Yast::WFM).to receive(:Execute).and_return(command_result)
        allow(Yast::SCR).to receive(:Execute).and_return(command_result)
        allow(Yast::SCR).to receive(:Write)
        allow(subject).to receive(:valid_language?).with(language).and_return(true)

        subject.Set(language)
        subject.SetDefault
    end

    it "writes .sysconfig.language.INSTALLED_LANGUAGES" do
      expect(Yast::SCR).to receive(:Write).with(Yast.path(".sysconfig.language.INSTALLED_LANGUAGES"), anything)

      subject.Save
    end

    it "cleans .sysconfig.language in sysconfig" do
      expect(Yast::SCR).to receive(:Write).with(Yast.path(".sysconfig.language"), nil)

      subject.Save
    end

    context "when language is zh_HK" do
      let(:language) { "zh_HK" }

      it "sets LC_MESSAGES to zh_TW" do
        expect(Yast::SCR).to receive(:Execute).with(anything, /.*localectl set-locale.*LC_MESSAGES.*zh_TW.*/)

        subject.Save
      end
    end

    context "when LC_MESAGES is zh_TW" do
      before do
        allow(subject).to receive(:@localed_conf).and_return({ "LC_MESSAGES" => "zh_TW" })
      end

      context "and language is not zh_HK" do
        it "cleans LC_MESSAGES" do
          expect(Yast::SCR).to_not receive(:Execute).with(anything, /.*localectl.*LC_MESSAGES.*zh_TW.*/)

          subject.Save
        end
      end
    end

    context "when using the readonly_language feature" do
      let(:readonly) { true }

      it "sets the default language using localectl" do
        expect(Yast::SCR).to receive(:Execute).with(anything, /.*localectl set-locale LANG.*=en_US.*/)

        subject.Save
      end
    end

    context "when not using the readonly_language feature" do
      it "sets the chosen language using localectl" do
        expect(Yast::SCR).to receive(:Execute).with(anything, /.*localectl set-locale LANG.*=#{language}.*/)

        subject.Save
      end
    end

    context "in the initial stage" do
      let(:initial_stage) { true }

      context "when using the readonly_language feature" do
        let(:readonly) { true }

        it "sets the default language using systemd-firstboot" do
          expect(Yast::WFM).to receive(:Execute).with(anything, /.*systemd-firstboot.*--locale.*en_US.*/)

          subject.Save
        end
      end

      context "when not using the readonly_language feature" do
        it "sets the chosen language using systemd-firstboot" do
          expect(Yast::WFM).to receive(:Execute).with(anything, /.*systemd-firstboot.*--locale.*#{language}.*/)

          subject.Save
        end
      end
    end

    context "when the command fails" do
      let(:command_result) { { "exit" => 1 } }

      it "reports an error" do
        expect(Yast::Report).to receive(:Error)

        subject.Save
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

  describe "#ResetRecommendedPackages" do
    it "resets the recommended packages" do
      allow(Yast::Pkg).to receive(:PkgSolve)
      expect(Yast::Pkg).to receive(:GetPackages).with(:selected, true).and_return(["foo"])
      expect(Yast::Pkg).to receive(:PkgNeutral).with("foo")
      subject.ResetRecommendedPackages
    end
  end

  describe "#SwitchToEnglishIfNeeded" do
    let(:normal?) { false }
    let(:textmode?) { true }
    let(:term) { "xterm" }
    let(:lang) { "de_DE" }

    before do
      allow(Yast::Stage).to receive(:normal).and_return(normal?)
      allow(subject).to receive(:GetTextMode).and_return(textmode?)
      allow(Yast::Builtins).to receive(:getenv).with("TERM").and_return(term)
    end

    around do |example|
      old_lang = Yast::Language.language
      Yast::Language.language = lang
      example.call
      Yast::Language.language = old_lang
    end

    context "when running on normal stage" do
      let(:normal?) { true}

      it "does not change the language" do
        expect(subject).to_not receive(:WfmSetGivenLanguage)
        subject.SwitchToEnglishIfNeeded(true)
      end

      it "returns false" do
        expect(subject.SwitchToEnglishIfNeeded(true)).to eq(false)
      end
    end

    context "when not running on textmode" do
      it "does not change the language" do
        expect(subject).to_not receive(:WfmSetGivenLanguage)
        subject.SwitchToEnglishIfNeeded(true)
      end
    end

    context "when running on fbiterm" do
      let(:term) { "iterm" }

      context "and it is using a supported language" do
        it "does not change the language" do
          expect(subject).to_not receive(:WfmSetGivenLanguage)
          subject.SwitchToEnglishIfNeeded(true)
        end

        it "returns false" do
          expect(subject.SwitchToEnglishIfNeeded(true)).to eq(false)
        end
      end

      context "and it is using a non supported language" do
        let(:lang) { "ar_EG" }

        it "changes the language to English" do
          expect(subject).to receive(:WfmSetGivenLanguage).with("en_US")
          subject.SwitchToEnglishIfNeeded(true)
        end

        it "displays an error message if asked to do so" do
          allow(Yast::Report).to receive(:Message).with(/selected language cannot be used/)
          subject.SwitchToEnglishIfNeeded(true)
        end

        it "does not display any error message if not asked to do so" do
          expect(Yast::Report).to_not receive(:Message)
          subject.SwitchToEnglishIfNeeded(false)
        end

        it "returns true" do
          expect(subject.SwitchToEnglishIfNeeded(true)).to eq(true)
        end
      end
    end

    context "when not running on fbiterm" do
      context "and it is not using a CJK language" do
        it "does not change the language" do
          expect(subject).to_not receive(:WfmSetGivenLanguage)
          subject.SwitchToEnglishIfNeeded(true)
        end

        it "returns false" do
          expect(subject.SwitchToEnglishIfNeeded(true)).to eq(false)
        end
      end

      context "and it is using a CJK language" do
        let(:lang) { "ja_JP" }

        it "changes the language to English" do
          expect(subject).to receive(:WfmSetGivenLanguage).with("en_US")
          subject.SwitchToEnglishIfNeeded(true)
        end

        it "displays an error message if asked to do so" do
          expect(Yast::Report).to receive(:Message).with(/selected language cannot be used/)
          subject.SwitchToEnglishIfNeeded(true)
        end

        it "does not display any error message if not asked to do so" do
          expect(Yast::Report).to_not receive(:Message)
          subject.SwitchToEnglishIfNeeded(false)
        end

        it "returns true" do
          expect(subject.SwitchToEnglishIfNeeded(true)).to eq(true)
        end
      end
    end
  end

  describe "#FillEnglishNames" do
    before do
      subject.main
    end

    it "does not modify the WFM language" do
      expect(subject.EnglishName("de_DE", "missing")).to eq("missing")
      subject.FillEnglishNames()
      expect(subject.EnglishName("de_DE", "missing")).to eq("German")
    end
  end
end

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
    allow(subject).to receive(:GetLanguagesMap).and_return(languages_map)

    Yast::Language.main
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

    before do
        allow(Yast::Stage).to receive(:initial).and_return(initial_stage)

        allow(Yast::ProductFeatures).to receive(:GetBooleanFeature)
          .with("globals", "readonly_language")
          .and_return(readonly)

        allow(Yast::SCR).to receive(:Write)
        allow(Yast::Execute).to receive(:locally!)
        allow(subject).to receive(:valid_language?).with(language).and_return(true)

        subject.Set(language)
        subject.SetDefault
    end

    it "updates the .sysconfig.language.INSTALLED_LANGUAGES value" do
      expect(Yast::SCR).to receive(:Write).with(Yast.path(".sysconfig.language.INSTALLED_LANGUAGES"), anything)

      subject.Save
    end

    it "forces writting .sysconfig.language to disk" do
      expect(Yast::SCR).to receive(:Write).with(Yast.path(".sysconfig.language"), nil)

      subject.Save
    end

    context "when language is zh_HK" do
      let(:language) { "zh_HK" }

      it "sets LC_MESSAGES to zh_TW" do
        expect(Yast::Execute).to receive(:locally!).with(array_including(/LC_MESSAGES=zh_TW/))

        subject.Save
      end
    end

    context "when LC_MESSAGES is zh_TW" do
      around do |example|
        original = subject.instance_variable_get(:@localed_conf)
        subject.instance_variable_set(:@localed_conf, { "LC_MESSAGES" => "zh_TW" })
        example.run
        subject.instance_variable_set(:@localed_conf, original)
      end

      context "and language is not zh_HK" do
        it "cleans LC_MESSAGES" do
          expect(Yast::Execute).to_not receive(:locally!).with(array_including(/LC_MESSAGES=zh_TW/))

          subject.Save
        end
      end
    end

    context "when using the readonly_language feature" do
      let(:readonly) { true }

      it "sets the default language using localectl" do
        expect(Yast::Execute).to receive(:locally!)
          .with(array_including(/localectl/, "set-locale", /LANG=en_US/))

        subject.Save
      end

      context "in the initial stage" do
        let(:initial_stage) { true }

        it "sets the default language using systemd-firstboot" do
          expect(Yast::Execute).to receive(:locally!)
            .with(array_including(/systemd-firstboot/, "--root", "--locale", /en_US/))

          subject.Save
        end
      end
    end

    context "when not using the readonly_language feature" do
      it "sets the chosen language using localectl" do
        expect(Yast::Execute).to receive(:locally!)
          .with(array_including(/localectl/, "set-locale", /LANG=#{language}/))

        subject.Save
      end

      context "in the initial stage" do
        let(:initial_stage) { true }

        it "sets the default language using systemd-firstboot" do
          expect(Yast::Execute).to receive(:locally!)
            .with(array_including(/systemd-firstboot/, "--root", "--locale", /#{language}/))

          subject.Save
        end
      end
    end

    context "when the command fails" do
      let(:exception) do
        Cheetah::ExecutionFailed.new(["localectl"], 1, "stdout", "stderr", "Something went wrong")
      end

      before do
        allow(Yast::Execute).to receive(:locally!).and_raise(exception)
      end

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
      before do
        subject.SetExpertValues("use_utf8" => false) # disable UTF-8
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

      Yast::Language.language = lang
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
          allow(Yast::Report).to receive(:Message)
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
          allow(Yast::Report).to receive(:Message)
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
          allow(Yast::Report).to receive(:Message)
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
          allow(Yast::Report).to receive(:Message)
          expect(subject.SwitchToEnglishIfNeeded(true)).to eq(true)
        end
      end
    end
  end

  describe "#FillEnglishNames" do
    it "does not modify the WFM language" do
      expect(subject.EnglishName("de_DE", "missing")).to eq("missing")
      subject.FillEnglishNames()
      expect(subject.EnglishName("de_DE", "missing")).to eq("German")
    end
  end

  describe "#main_language" do
    it "returns empty string for nil" do
      expect(subject.main_language(nil)).to eq ""
    end

    it "returns main language for variant with dialect" do
      expect(subject.main_language("en_GB")).to eq "en"
    end

    it "returns main language for variant with dialect and encoding" do
      expect(subject.main_language("en_GB.utf-8")).to eq "en"
    end

    # test for bsc#949591
    it "returns main language even when it has more then two chars" do
      expect(subject.main_language("csb_PL")).to eq "csb"
    end
  end

  describe "#Export" do
    it "returns map with language" do
      subject.language = "cs_CZ.utf8"
      expect(subject.Export).to include("language" => "cs_CZ.utf8")
    end

    it "returns map with installed languages" do
      subject.languages = "cs_CZ,en_US"
      expect(subject.Export).to include("languages" => "cs_CZ,en_US")
    end

    it "returns map with use_utf8 if utf is not used" do
      subject.SetExpertValues("use_utf8" => false)
      expect(subject.Export).to include("use_utf8" => false)
    end

    context "language settings are default values" do
      before do
        subject.language = subject.default_language
        subject.languages = []
        subject.SetExpertValues("use_utf8" => true)
      end

      it "exports an empty hash for the AutoYaST profile" do
        expect(subject.Export).to eq({})
      end
    end
  end

  describe "#Import" do
    it "sets language from map" do
      subject.Import("language" => "de_DE")

      expect(subject.language).to eq "de_DE"
    end

    it "sets utf-8 encoding from map" do
      subject.Import("use_utf8" => false)

      expect(subject.GetExpertValues["use_utf8"]).to eq false
    end

    it "sets installed languages from map" do
      subject.Import("languages" => "de_DE,cs_CZ", "language" => "de_DE")

      expect(subject.languages).to eq "de_DE,cs_CZ"
    end

    it "adds to installed languages language from map" do
      subject.Import("languages" => "cs_CZ", "language" => "de_DE")

      expect(subject.languages).to eq "cs_CZ,de_DE"
    end

    context "in autoinstallation" do
      before do
        allow(Yast::Mode).to receive(:autoinst).and_return(true)
      end

      it "sets package locale to imported language" do
        expect(Yast::Pkg).to receive(:SetPackageLocale).with("de_DE")

        subject.Import("language" => "de_DE")
      end

      it "sets additional locales to imported languages" do
        expect(Yast::Pkg).to receive(:SetAdditionalLocales).with(["de_DE", "cs_CZ"])

        subject.Import("languages" => "de_DE,cs_CZ", "language" => "de_DE")
      end
    end
  end

  describe "#Summary" do
    it "returns string with html list" do
      expect(subject.Summary).to be_a(::String)
      expect(subject.Summary).to include("<ul>")
    end
  end

  describe "#IncompleteTranslation" do
    it "returns true if language translation is lower than threshold" do
      allow(Yast::FileUtils).to receive(:Exists).and_return(true)
      allow(Yast::SCR).to receive(:Read).and_return("15")
      allow(Yast::ProductFeatures).to receive(:GetStringFeature)
        .with("globals", "incomplete_translation_treshold")
        .and_return("90")

      expect(subject.IncompleteTranslation("cs_CZ")).to eq true
    end

    it "returns false otherwise" do
      allow(Yast::FileUtils).to receive(:Exists).and_return(true)
      allow(Yast::SCR).to receive(:Read).and_return("95")
      allow(Yast::ProductFeatures).to receive(:GetStringFeature)
        .with("globals", "incomplete_translation_treshold")
        .and_return("90")

      expect(subject.IncompleteTranslation("cs_CZ")).to eq false
    end
  end

  describe "#GetGivenLanguageCountry" do
    it "returns country part of passed language" do
      expect(subject.GetGivenLanguageCountry("de_AT@UTF8")).to eq "AT"
      expect(subject.GetGivenLanguageCountry("de_AT.UTF8")).to eq "AT"
      expect(subject.GetGivenLanguageCountry("de_AT")).to eq "AT"
    end

    it "returns upper cased language if country part is missing" do
      expect(subject.GetGivenLanguageCountry("de")).to eq "DE"
    end
  end

  describe "#Read" do
    context "really is set to true" do
      it "reads language from localed.conf" do
        allow(Y2Country).to receive(:read_locale_conf).and_return("LANG" => "de_DE.UTF-8")

        expect{subject.Read(true)}.to change{subject.language}.to("de_DE")
      end

      it "reads languages from sysconfig" do
        allow(Yast::Misc).to receive(:SysconfigRead).and_return("cs_CZ,de_DE")

        expect{subject.Read(true)}.to change{subject.languages}.to("cs_CZ,de_DE")
      end

      it "reads utf8 settings during runtime" do
        allow(Y2Country).to receive(:read_locale_conf).and_return("LANG" => "de_DE.UTF-8")
        subject.SetExpertValues("use_utf8" => false)

        expect{subject.Read(true)}.to change{subject.GetExpertValues["use_utf8"]}.from(false).to(true)
      end
    end

    it "sets initial language" do
      subject.language = "cs_CZ"

      expect{subject.Read(false)}.to change{subject.language_on_entry}.to("cs_CZ")
    end

    it "sets initial languages" do
      subject.languages = "cs_CZ,de_DE"

      expect{subject.Read(false)}.to change{subject.languages_on_entry}.to("cs_CZ,de_DE")
    end

    it "clears expert settings changed flag" do
      subject.ExpertSettingsChanged = true

      expect{subject.Read(false)}.to change{subject.ExpertSettingsChanged}.from(true).to(false)
    end
  end

  describe "#MakeProposal" do
    context "force_reset is set to true" do
      it "sets default language" do
        subject.language = "de_DE"
        subject.SetDefault

        subject.language = "cs_CZ"

        expect{subject.MakeProposal(true, false)}.to change{subject.language}.from("cs_CZ").to("de_DE")
      end
    end

    context "language changed is set to true" do
      it "forces read of languages map" do
        expect(subject).to receive(:read_languages_map)

        subject.MakeProposal(false, true)
      end
    end

    it "returns array of string with proposal text" do
      expect(subject.MakeProposal(false, false)).to be_a(::Array)
      expect(subject.MakeProposal(false, false)).to all(be_a(::String))
    end

    # TODO: also not clear magic with additional languages done in proposal
  end
end

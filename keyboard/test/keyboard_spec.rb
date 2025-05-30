#!/usr/bin/env rspec
# coding: utf-8

require_relative "test_helper"
require "y2keyboard/keyboards"

Yast.import "Keyboard"

describe "Yast::Keyboard" do
  subject { Yast::Keyboard }

  before do
    allow(File).to receive(:executable?).with("/usr/sbin/xkbctrl").and_return(false)
  end

  describe "#GetKeyboardForLanguage" do
    let (:search_language) {"en_US"}

    before do
      allow(Keyboards).to receive(:suggested_keyboard).with(search_language).
        and_return(nil)
    end

    context "regarding keyboard has been defined" do
      it "returns regarding keyboard" do
        expect(Yast::Language).to receive(:GetLang2KeyboardMap).with(true).
          and_return({search_language => "english-us"})
        expect(subject.GetKeyboardForLanguage(search_language,
          "default_language")).to eq("english-us")
      end
    end

    context "regarding keyboard has not been defined" do
      it "returns default keyboard" do
        expect(Yast::Language).to receive(:GetLang2KeyboardMap).with(true).
          and_return({})
        expect(subject.GetKeyboardForLanguage(search_language,
          "default_language")).to eq("default_language")
      end
    end
  end

  describe "#Read" do
    before do
      allow(Yast::Stage).to receive(:initial).and_return false
    end

    it "sets the current keyboard" do
      allow_any_instance_of(Y2Keyboard::Strategies::SystemdStrategy).
        to receive(:current_layout).and_return("gb")
      subject.Read
      expect(subject.current_kbd).to eq("english-uk")
    end

    it "sets empty current keyboard for unsupported keyboard (bsc#1159286)" do
      # something usable for localectl but not in our data
      allow_any_instance_of(Y2Keyboard::Strategies::SystemdStrategy).
        to receive(:current_layout).and_return("lt-lekpa")
      subject.Read
      expect(subject.current_kbd).to eq("")
    end

    it "converts a legacy keymap code to a current one" do
      allow_any_instance_of(Y2Keyboard::Strategies::SystemdStrategy).
        to receive(:current_layout).and_return("fr-latin1")
      subject.Read
      expect(subject.current_kbd).to eq("french")
    end
  end

  describe "#Save" do
    context "in update mode" do
      before do
        allow(Yast::Mode).to receive(:update).and_return true
      end

      it "does not save settings" do
        expect_any_instance_of(Y2Keyboard::Strategies::SystemdStrategy).
          not_to receive(:apply_layout)
        subject.Save
      end
    end

    context "in none update mode" do
      before do
        allow(Yast::Mode).to receive(:update).and_return false
      end

      it "saves settings to current system" do
        expect_any_instance_of(Y2Keyboard::Strategies::SystemdStrategy).
          to receive(:apply_layout).with("de")
        subject.Set("german-deadkey")
        subject.Save
      end
    end
  end

  describe "#Set" do
    context "in AY configuration mode" do
      before do
        allow(Yast::Mode).to receive(:config).and_return true
      end

      it "does not set the keyboard" do
        expect_any_instance_of(Y2Keyboard::Strategies::KbStrategy).
          not_to receive(:set_layout)
        subject.Set("german")
      end
    end

    context "in none AY configuration mode" do
      before do
        allow(Yast::Mode).to receive(:update).and_return false
      end

      it "sets keyboard" do
        expect_any_instance_of(Y2Keyboard::Strategies::KbStrategy).
          to receive(:set_layout).with("de")
        subject.Set("german-deadkey")
        expect(subject.current_kbd).to eq("german-deadkey")
      end
    end
  end

  describe "#MakeProposal" do
    context "force_reset is true" do

      it "resets to default keyboard if defined" do
        # set default keyboard
        subject.Set("german")
        subject.SetKeyboardDefault()
        subject.Set("english-us")

        subject.MakeProposal(true, false)
        expect(subject.current_kbd).to eq("german")
      end
    end

    context "force_reset is false" do
      before do
        allow(Yast::Mode).to receive(:mode).and_return("installation")
      end

      context "User has already decided" do

        it "does not make a proposal" do
          subject.user_decision = true
          expect(subject).not_to receive(:Set)
          subject.MakeProposal(false, false)
        end
      end

      context "User has not make any decision" do

        it "makes a proposal" do
          subject.user_decision = false
          expect(subject).to receive(:Set)
          subject.MakeProposal(false, false)
        end
      end

      context "AutoYaST has not defined a keyboard" do
        subject { Yast::KeyboardClass.new }
        before do
          allow(Yast::Mode).to receive(:auto).and_return true
        end
        it "makes a proposal" do
          subject.main()
          expect(subject).to receive(:Set)
          subject.MakeProposal(false, false)
        end
      end
    end
  end

  describe "#Selection" do
    it "returns a keyboard description map" do
      ret = subject.Selection
      expect(ret["arabic"]).to eq("Arabic")
    end
  end

  describe "#GetKeyboardItems" do
    it "returns map of keyboard items" do
      ret = subject.GetKeyboardItems
      expect(ret.first.params[0]).to be_kind_of(Yast::Term)
      expect(ret.first.params[0].value).to eq(:id)
      expect(ret.first.params[1]).to be_kind_of(String)
      expect(ret.first.params[2].class == FalseClass ||
        ret.first.params[2].class == TrueClass).to eq(true)
    end
  end

  describe "#SetKeyboardForLanguage" do
    it "sets keyboard temporarily in the running system" do
      expect(subject).to receive(:Set).with("english-us")
      subject.SetKeyboardForLanguage("en")
    end
  end

  describe "#SetKeyboardDefault" do
    before do
      allow_any_instance_of(Y2Keyboard::Strategies::SystemdStrategy).
        to receive(:current_layout).and_return("gb")
    end

    it "sets keyboard default to current keyboard" do
      subject.Read()
      subject.SetKeyboardDefault
      expect(subject.default_kbd).to eq(subject.current_kbd)
    end
  end

  describe "#Export" do
    let(:profile) {{ "keymap" => "english-us" }}

    before do
      subject.Set("english-us")
    end

    context "keyboard settings are default values, depending on language" do
      before do
        allow(subject).to receive(:GetKeyboardForLanguage).
          and_return("english-us")
      end

      it "exports an empty hash for the AutoYaST profile" do
        expect(subject.Export).to eq({})
      end
    end

    context "keyboard settings are not default values" do
      before do
        allow(subject).to receive(:GetKeyboardForLanguage).
          and_return("german")
      end

      it "exports keyboard information for the AutoYaST profile" do
        expect(subject.Export).to eq(profile)
      end
    end
  end

  describe "#Import" do
    before do
      allow_any_instance_of(Y2Keyboard::Strategies::SystemdStrategy).
        to receive(:current_layout).and_return("dk")
    end

    context "data comes from language settings" do
      it "sets the keyboard" do
        expect(subject).to receive(:Set).with("german")
        subject.Import({"keymap" => "german"}, :keyboard)
      end
    end

    context "data comes from keyboard settings" do
      it "evaluates and sets the keyboard by the given language" do
        expect(subject).to receive(:Set).with("german")
        subject.Import({"language" => "de"}, :language)
      end
    end

    context "keymap value is given instead of an alias name" do
      it "sets the alias name" do
        expect(subject).to receive(:Set).with("spanish")
        subject.Import({"keymap" => "es"}, :keyboard)
      end
    end

    context "keymap value is a legacy keymap" do
      before do
        allow_any_instance_of(Y2Keyboard::Strategies::SystemdStrategy).
          to receive(:current_layout).and_return("no")
      end

      it "converts the legacy keymap code to a current one" do
        expect(subject).to receive(:Set).with("french")
        subject.Import({"keymap" => "fr-latin1"}, :keyboard)
      end
    end

    context "keymap is unknown" do
      it "reports a warning" do
        expect(subject).not_to receive(:Set)
        expect(Yast::Report).to receive(:Warning).with(/Cannot find keymap/)
        subject.Import({"keymap" => "foo"}, :keyboard)
      end
    end
  end

end

#!/usr/bin/env rspec
# coding: utf-8

require_relative "test_helper"
require_relative "../src/data/keyboards"

Yast.import "Keyboard"

describe "Yast::Keyboard" do
  subject { Yast::Keyboard }

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
    it "returns the current keyboard" do
      allow(Yast::Stage).to receive(:initial).and_return false
      expect_any_instance_of(Y2Keyboard::Strategies::SystemdStrategy).
        to receive(:current_layout).and_return("uk")
      subject.Read
      expect(subject.current_kbd).to eq("english-uk")
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
          to receive(:apply_layout).with("de-latin1-nodeadkeys")
        subject.Set("german")
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
          to receive(:set_layout).with("de-latin1-nodeadkeys")
        subject.Set("german")
        expect(subject.current_kbd).to eq("german")
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
        to receive(:current_layout).and_return("uk")
    end

    it "sets keyboard default to current keyboard" do
      subject.Read()
      subject.SetKeyboardDefault
      expect(subject.default_kbd).to eq(subject.current_kbd)
    end
  end

  describe "#Import" do
    before do
      allow_any_instance_of(Y2Keyboard::Strategies::SystemdStrategy).
        to receive(:current_layout).and_return("uk")
    end

    context "data comes from language settings" do
      it "sets the keyboard" do
        expect(subject).to receive(:Set).with("german")
        subject.Import({"keymap" => "german"}, :keyboard)
      end
    end

    context "data comes from keyboard settings" do
      it "evaluates and sets the keyboard by the given language" do
        expect(subject).to receive(:Set).with("german-deadkey")
        subject.Import({"language" => "de"}, :language)
      end
    end
  end

end

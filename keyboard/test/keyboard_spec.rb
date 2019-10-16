#!/usr/bin/env rspec
# coding: utf-8

require_relative "test_helper"
require_relative "../src/data/keyboards"

Yast.import "ProductFeatures"
Yast.import "Keyboard"
Yast.import "Language"

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

end

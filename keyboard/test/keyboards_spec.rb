#!/usr/bin/env rspec
# coding: utf-8

require_relative "test_helper"
require "y2keyboard/keyboards"

describe "Keyboards" do
  subject { Keyboards }

  describe ".all_keyboards" do
    it "returns a map of all available keyboard descriptions" do
      ret = subject.all_keyboards
      expect(ret.first.key?("description")).to eq(true)
      expect(ret.first.key?("alias")).to eq(true)
      expect(ret.first.key?("code")).to eq(true)
      if ret.first.key?("suggested_for_lang")
        expect(ret.first["suggested_for_lang"].class == Array).to eq(true)
      end
    end

    it "returns a list with all valid models from systemd" do
      # read valid codes from systemd as xkbctrl read it from there
      valid_codes = Keyboards.kbd_model_map_lines
      valid_codes.map! { |l| l.strip.sub(/^(\S+)\s+.*$/, "\\1") }
      Keyboards.all_keyboards.each do |kb_map|
        code = kb_map["code"]
        expect(valid_codes).to include(code)
      end
    end
  end

  describe ".suggested_keyboard" do
    context "given language found" do
      it "returns the proposed keyboard for a given language" do
        expect(subject.suggested_keyboard("de_CH")).to eq("german-ch")
      end
    end

    context "given language not found" do
      it "returns nil" do
        expect(subject.suggested_keyboard("wrong_language")).to eq(nil)
      end
    end
  end

  describe ".alias" do
    context "given keymap found" do
      it "evaluates alias name for a given keymap" do
        expect(subject.alias("de")).to eq("german-deadkey")
      end
    end

    context "given keymap not found" do
      it "returns nil" do
        expect(subject.alias("wrong_keymap")).to eq(nil)
      end
    end
  end

  describe ".description" do
    context "given keyboard alias found" do
      it "evaluates description for a given keyboard" do
        expect(subject.description("english-us")).not_to be_empty
      end
    end

    context "given keyboard alias not found" do
      it "returns nil" do
        expect(subject.description("wrong_keyboard")).to eq(nil)
      end
    end
  end

  describe ".code" do
    context "given keyboard alias found" do
      it "evaluates keymap for a given keyboard" do
        expect(subject.code("english-us")).to eq("us")
      end
    end

    context "given keyboard alias not found" do
      it "returns nil" do
        expect(subject.description("wrong_alias")).to eq(nil)
      end
    end
  end

  describe ".legacy_code?" do
    it "detects known legacy_codes" do
      expect(subject.legacy_code?("de-latin1")).to eq(true)
      expect(subject.legacy_code?("sg-latin1")).to eq(true)
    end

    it "rejects known current keymap codes" do
      expect(subject.legacy_code?("de")).to eq(false)
      expect(subject.legacy_code?("ch")).to eq(false)
    end

    it "survives nil" do
      expect(subject.legacy_code?(nil)).to eq(false)
    end
  end

  describe ".legacy_replacement" do
    it "translates legacy keymap codes correctly" do
      expect(subject.legacy_replacement("de-latin1")).to eq("de")
      expect(subject.legacy_replacement("sg-latin1")).to eq("ch")
    end

    it "returns the original keymap code if it is not found as a legacy_code" do
      expect(subject.legacy_replacement("de")).to eq("de")
      expect(subject.legacy_replacement("fr")).to eq("fr")
    end

    it "survives nil" do
      expect(subject.legacy_replacement(nil)).to eq("us")
    end
  end

  describe "keyboard table consistency:" do
    it "has all required hash keys" do
      subject.all_keyboards.each do |kb|
        expect(kb.keys).to include("description", "alias", "code")
      end
    end

    it "does not have unexpected hash keys" do
      subject.all_keyboards.each do |kb|
        unknown_keys = kb.keys - ["description", "alias", "code", "legacy_code","suggested_for_lang"]
        expect(unknown_keys).to be_empty, "unknown #{unknown_keys} in #{kb}"
      end
    end

    it "no legacy_code is also a current code" do
      current_codes = subject.all_keyboards.map { |kb| kb["code"] }
      legacy_codes = subject.all_keyboards.map { |kb| kb["legacy_code"] }.compact
      ambiguous = current_codes & legacy_codes
      expect(ambiguous).to be_empty, "legacy_code cannot be a current code: #{ambiguous}"
    end
  end

end

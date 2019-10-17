#!/usr/bin/env rspec
# coding: utf-8

require_relative "test_helper"
require_relative "../src/data/keyboards"

describe "Keyboards" do
  subject { Keyboards }

  describe "#all_keyboards" do
    it "returns map of all available keyboard descriptions" do
      ret = subject.all_keyboards
      expect(ret.first.key?("description")).to eq(true)
      expect(ret.first.key?("alias")).to eq(true)
      expect(ret.first.key?("code")).to eq(true)
      if ret.first.key?("suggested_for_lang")
        expect(ret.first["suggested_for_lang"].class == Array).to eq(true)
      end
    end
  end

  describe "#suggested_keyboard" do
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

  describe "#alias" do
    context "given keymap found" do
      it "evaluates alias name for a given keymap" do
        expect(subject.alias("de-latin1-nodeadkeys")).to eq("german")
      end
    end

    context "given keymap not found" do
      it "returns nil" do
        expect(subject.alias("wrong_keymap")).to eq(nil)
      end
    end
  end

  describe "#description" do
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

  describe "#code" do
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

end

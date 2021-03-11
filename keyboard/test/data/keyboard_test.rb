#!/usr/bin/env rspec
# coding: utf-8

require_relative "../test_helper"
require_relative "../../src/data/keyboards"

describe Keyboards do
  describe ".all_keyboards" do
    it "returns list with all code valid" do
      # read valid codes from systemd as xkbctrl read it from there
      valid_codes = File.readlines("/usr/share/systemd/kbd-model-map")
      valid_codes.map! { |l| l.strip.sub(/^(\S+)\s+.*$/, "\\1") }
      Keyboards.all_keyboards.each do |kb_map|
        code = kb_map["code"]
        expect(valid_codes).to include(code)
      end
    end
  end
end

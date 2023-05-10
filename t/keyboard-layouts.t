#!/usr/bin/env ruby

require_relative "tap_helper"

tap = TAP.new

tap.test "Keyboards.all_keyboards members only includes items known to localectl" do
  require "yast"
  require "y2keyboard/keyboards"

  cmd = "localectl list-keymaps"
  localectl_keymaps = `#{cmd}`.split("\n")
  raise "Could not get the list of keymaps from localectl" if localectl_keymaps.empty?

  Keyboards.all_keyboards.each do |kb_map|
    code = kb_map["code"]
    next if localectl_keymaps.include?(code)

    raise "YaST keyboard #{kb_map.inspect} not found in '#{cmd}'"
  end
end

tap.run

# encoding: utf-8

# tests for Timezone::UpdateTimezone
# Author: jsuchome@suse.cz
# $Id$
module Yast
  class UpdateTimezoneClient < Client
    def main
      # testedfiles: Timezone.ycp

      Yast.include self, "testsuite.rb"

      @READ = {
        "sysconfig" => {
          "clock" => { "TIMEZONE" => "Europe/Prague", "HWCLOCK" => "-u" }
        },
        "target"    => { "size" => 1, "yast2" => {} },
        "etc"       => { "adjtime" => ["0", "0", "UTC"] }
      }
      @EXECUTE = { "target" => { "bash_output" => {} } }

      TESTSUITE_INIT([@READ, {}, @EXECUTE], nil)

      Yast.import "Timezone"

      TEST(lambda { Timezone.UpdateTimezone("US/Pacific") }, [], [])

      TEST(lambda { Timezone.UpdateTimezone("Australia/Adelaide") }, [], [])

      TEST(lambda { Timezone.UpdateTimezone("Australia/South") }, [], [])

      nil
    end
  end
end

Yast::UpdateTimezoneClient.new.main

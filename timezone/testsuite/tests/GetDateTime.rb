# encoding: utf-8

# tests for Timezone::GetDateTime
# Author: jsuchome@suse.cz
# $Id$
module Yast
  class GetDateTimeClient < Client
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

      @E = {
        "target" => { "bash_output" => { "stdout" => "00:00:00 - 0001-01-01" } }
      }

      TEST(lambda { Timezone.GetDateTime(false, true) }, [{}, {}, @E], [])

      TEST(lambda { Timezone.GetDateTime(false, false) }, [{}, {}, @E], [])

      Timezone.hwclock = "--localtime"

      # without TZ=
      TEST(lambda { Timezone.GetDateTime(false, false) }, [{}, {}, @E], [])

      Timezone.hwclock = "-u"
      Timezone.diff = 1 #not possible to check 2 SCR calls with different bash_output/stdout

      TEST(lambda { Timezone.GetDateTime(false, false) }, [{}, {}, @E], [])

      nil
    end
  end
end

Yast::GetDateTimeClient.new.main

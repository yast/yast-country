# encoding: utf-8

# test for Timezone::GetDateTimeMap
#	- check correct parsing after changed time format (bug #62312)
# Author: jsuchome@suse.cz
# $Id$
module Yast
  class GetDateTimeMapClient < Client
    def main
      # testedfiles: Timezone.ycp

      Yast.import "Testsuite"

      @READ = {
        "sysconfig" => {
          "clock" => { "DEFAULT_TIMEZONE" => "Europe/Prague", "HWCLOCK" => "-u" }
        },
        "target"    => { "size" => 1, "yast2" => {} },
        "etc"       => { "adjtime" => ["0", "0", "UTC"] }
      }
      @EXECUTE = { "target" => { "bash_output" => {} } }

      Testsuite.Init([@READ, {}, @EXECUTE], nil)

      Yast.import "Timezone"

      @E = {
        "target" => { "bash_output" => { "stdout" => "23:59:59 - 0000-12-24" } }
      }

      Testsuite.Test(lambda { Timezone.GetDateTimeMap }, [{}, {}, @E], [])

      nil
    end
  end
end

Yast::GetDateTimeMapClient.new.main

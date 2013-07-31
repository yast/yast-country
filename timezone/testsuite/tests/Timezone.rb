# encoding: utf-8

# tests for Timezone.ycp constructor
# Author: jsuchome@suse.cz
# $Id$
module Yast
  class TimezoneClient < Client
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

      nil
    end
  end
end

Yast::TimezoneClient.new.main

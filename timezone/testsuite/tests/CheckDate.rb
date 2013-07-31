# encoding: utf-8

# tests for Timezone::GetDateTime
# Author: jsuchome@suse.cz
# $Id$
module Yast
  class CheckDateClient < Client
    def main
      # testedfiles: Timezone.ycp

      Yast.import "Testsuite"

      @READ = {
        "sysconfig" => {
          "clock" => { "TIMEZONE" => "Europe/Prague", "HWCLOCK" => "-u" }
        },
        "target"    => { "size" => 1, "yast2" => {} },
        "etc"       => { "adjtime" => ["0", "0", "UTC"] }
      }
      @EXECUTE = { "target" => { "bash_output" => {} } }

      Testsuite.Init([@READ, {}, @EXECUTE], nil)

      Yast.import "Timezone"

      Testsuite.Test(lambda { Timezone.CheckDate("1", "2", "2000") }, [], [])

      Testsuite.Test(lambda { Timezone.CheckDate("29", "2", "2000") }, [], [])

      # wrong dates:
      Testsuite.Test(lambda { Timezone.CheckDate("29", "2", "2001") }, [], [])

      Testsuite.Test(lambda { Timezone.CheckDate("33", "2", "2000") }, [], [])

      Testsuite.Test(lambda { Timezone.CheckDate("33", "13", "2000") }, [], [])

      Testsuite.Test(lambda { Timezone.CheckDate("1", "1", "2033") }, [], [])

      # wrong input
      Testsuite.Test(lambda { Timezone.CheckDate("", "2", "2000") }, [], [])

      Testsuite.Test(lambda { Timezone.CheckDate("1", "", "2000") }, [], [])

      Testsuite.Test(lambda { Timezone.CheckDate("1", "2", "blah") }, [], [])

      nil
    end
  end
end

Yast::CheckDateClient.new.main

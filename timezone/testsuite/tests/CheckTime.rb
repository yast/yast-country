# encoding: utf-8

# tests for Timezone::GetDateTime
# Author: jsuchome@suse.cz
# $Id$
module Yast
  class CheckTimeClient < Client
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

      Testsuite.Test(lambda { Timezone.CheckTime("1", "2", "3") }, [], [])

      # wrong time:
      Testsuite.Test(lambda { Timezone.CheckTime("24", "2", "3") }, [], [])

      Testsuite.Test(lambda { Timezone.CheckTime("1", "62", "3") }, [], [])

      Testsuite.Test(lambda { Timezone.CheckTime("1", "2", "63") }, [], [])

      # wrong input:
      Testsuite.Test(lambda { Timezone.CheckTime("", "2", "3") }, [], [])

      Testsuite.Test(lambda { Timezone.CheckTime("1", "2", "blah") }, [], [])

      nil
    end
  end
end

Yast::CheckTimeClient.new.main

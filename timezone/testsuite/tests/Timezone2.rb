# encoding: utf-8

# tests for Timezone.ycp constructor
# Author: jsuchome@suse.cz
# $Id$
module Yast
  class Timezone2Client < Client
    def main
      # testedfiles: Timezone.ycp

      Yast.import "Testsuite"

      @READ = {
        "sysconfig" => {
          "clock" => { "TIMEZONE" => "Europe/Prague", "HWCLOCK" => "-u" }
        },
        "target"    => {
          "size"    => 1,
          "yast2"   => {},
          "lstat"   => { "islink" => true },
          "symlink" => "/usr/share/zoneinfo/Europe/Berlin"
        },
        "etc"       => { "adjtime" => ["0", "0", "UTC"] }
      }
      @EXECUTE = { "target" => { "bash_output" => {} } }



      Testsuite.Init([@READ, {}, @EXECUTE], nil)

      Yast.import "Timezone"

      Testsuite.Test(lambda { Timezone.Export }, [], nil)

      nil
    end
  end
end

Yast::Timezone2Client.new.main

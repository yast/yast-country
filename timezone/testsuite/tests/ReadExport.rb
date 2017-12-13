# encoding: utf-8

# tests for Timezone.ycp autoyast functions: preparation for cloning
# Author:	jsuchome@suse.cz
# $Id$
module Yast
  class ReadExportClient < Client
    def main
      # testedfiles: Timezone.ycp

      Yast.import "Testsuite"

      @READ = {
        "sysconfig" => {
          "clock" => { "DEFAULT_TIMEZONE" => "Europe/Prague", "HWCLOCK" => "-u" }
        },
        "target"    => { "size" => 1, "dir" => [], "yast2" => {} },
        "etc"       => { "adjtime" => ["0", "0", "LOCAL"] }
      }

      @E = { "target" => { "bash_output" => {} } }

      Yast.import "Mode"

      Mode.SetMode("autoinst_config")

      Testsuite.Init([@READ, {}, @E], nil)

      Yast.import "Timezone"

      Ops.set(
        @READ,
        ["target", "yast2"],
        [
          {
            "name"    => "Europe",
            "entries" => { "Europe/Prague" => "Czech Republic" }
          }
        ]
      )

      Testsuite.Test(lambda { Timezone.Read }, [@READ, {}, @E], nil)

      Testsuite.Test(lambda { Timezone.Export }, [], nil)

      Testsuite.Test(lambda { Timezone.Summary }, [], nil)

      Testsuite.Test(lambda { Timezone.Modified }, [], nil)

      nil
    end
  end
end

Yast::ReadExportClient.new.main

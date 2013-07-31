# encoding: utf-8

# tests for Timezone.ycp autoyast functions
# Author:	jsuchome@suse.cz
# $Id$
module Yast
  class ImportExportClient < Client
    def main
      # testedfiles: Timezone.ycp

      Yast.import "Testsuite"

      @READ = {
        "target" => { "size" => 1, "dir" => [], "yast2" => {} },
        "etc"    => { "adjtime" => ["0", "0", "UTC"] }
      }

      @E = { "target" => { "bash_output" => {} } }

      Yast.import "Mode"
      Mode.SetMode("autoinst_config")

      Testsuite.Init([@READ, {}, @E], nil)

      Yast.import "Timezone"

      Testsuite.Test(lambda { Timezone.Export }, [], nil)

      Testsuite.Test(lambda { Timezone.Modified }, [], nil)

      @imported = { "timezone" => "Europe/Berlin" }

      Testsuite.Test(lambda { Timezone.Import(@imported) }, [{}, {}, @E], nil)

      Testsuite.Test(lambda { Timezone.Modified }, [], nil)

      Testsuite.Test(lambda { Timezone.Export }, [], nil)

      Testsuite.Test(lambda { Timezone.Summary }, [], nil)

      nil
    end
  end
end

Yast::ImportExportClient.new.main

# encoding: utf-8

# tests for Language.ycp autoyast functions: prepare for cloning
# Author:	jsuchome@suse.cz
# $Id$
module Yast
  class ReadExportClient < Client
    def main
      # testedfiles: Language.ycp

      Yast.import "Testsuite"

      @READ = {
        "sysconfig" => {
          "language" => {
            "RC_LANG"             => "de_DE.UTF-8",
            "INSTALLED_LANGUAGES" => "en_US,de_DE"
          }
        },
        "target"    => {
          "size"  => 1,
          "dir"   => ["language_de_DE.ycp"],
          "yast2" => {
            "de_DE" => ["Deutsch", "Deutsch", ".UTF-8", "@euro", "German"],
            "en_US" => ["English", "English", ".UTF-8", "@euro", "English"]
          }
        }
      }

      @E = { "target" => { "bash_output" => {} } }

      Yast.import "Mode"
      Mode.SetMode("autoinst_config")

      Testsuite.Init([@READ, {}, @E], nil)

      Yast.import "Language"

      Testsuite.Test(lambda { Language.Read(true) }, [@READ, {}, @E], nil)

      Testsuite.Test(lambda { Language.Export }, [], nil)

      Testsuite.Test(lambda { Language.Summary }, [], nil)

      Testsuite.Test(lambda { Language.Modified }, [], nil)

      nil
    end
  end
end

Yast::ReadExportClient.new.main

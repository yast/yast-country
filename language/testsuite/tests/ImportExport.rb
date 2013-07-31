# encoding: utf-8

# tests for Language.ycp autoyast functions
# Author:	jsuchome@suse.cz
# $Id$
module Yast
  class ImportExportClient < Client
    def main
      # testedfiles: Language.ycp

      Yast.import "Testsuite"

      @READ = {
        "sysconfig" => { "language" => { "DEFAULT_LANGUAGE" => "en_US" } },
        "target"    => {
          "dir"   => ["language_de_DE.ycp"],
          "yast2" => {
            "de_DE" => ["Deutsch", "Deutsch", ".UTF-8", "@euro", "German"]
          }
        }
      }

      @E = { "target" => { "bash_output" => {} } }

      Yast.import "Mode"
      Mode.SetMode("autoinst_config")

      Testsuite.Init([@READ, {}, @E], nil)

      Yast.import "Language"

      Testsuite.Test(lambda { Language.Export }, [], nil)

      Testsuite.Test(lambda { Language.Modified }, [], nil)

      @imported = { "language" => "de_DE" }

      Testsuite.Test(lambda { Language.Import(@imported) }, [@READ, {}, @E], nil)

      Testsuite.Test(lambda { Language.Modified }, [], nil)

      Testsuite.Test(lambda { Language.Export }, [], nil)

      Testsuite.Test(lambda { Language.Summary }, [], nil)

      # now let's add another language
      @imported = { "languages" => "cs_CZ" }

      Testsuite.Test(lambda { Language.Import(@imported) }, [{}, {}, @E], nil)

      Testsuite.Test(lambda { Language.Export }, [], nil)

      # cs_CZ not shown in summary, as it was not part of READ map
      Testsuite.Test(lambda { Language.Summary }, [], nil)

      nil
    end
  end
end

Yast::ImportExportClient.new.main

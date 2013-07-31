# encoding: utf-8

# tests for Language.ycp functions
# Maintainer:	jsuchome@suse.cz
# $Id$
module Yast
  class LanguageClient < Client
    def main
      # testedfiles: Language.ycp

      Yast.include self, "testsuite.rb"

      @READ = {
        "sysconfig" => { "language" => { "DEFAULT_LANGUAGE" => "en_US" } },
        "target"    => { "bash_output" => {}, "size" => 1, "yast2" => {} }
      }

      TESTSUITE_INIT([@READ, {}, @READ], nil)
      Yast.import "Pkg"
      Yast.import "Language"

      DUMP("GetLanguageCountry")
      Language.language = "de_AT@UTF-8"
      TEST(lambda { Language.GetLanguageCountry }, [], nil)
      Language.language = "de_AT"
      TEST(lambda { Language.GetLanguageCountry }, [], nil)
      Language.language = "de"
      TEST(lambda { Language.GetLanguageCountry }, [], nil)

      Language.language = "" # use default language

      TEST(lambda { Language.GetLanguageCountry }, [], nil)

      nil
    end
  end
end

Yast::LanguageClient.new.main

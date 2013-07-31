# encoding: utf-8

# tests for Language::IncompleteTranslation
# Author:	jsuchome@suse.cz
# $Id$
module Yast
  class IncompleteTranslationClient < Client
    def main
      # testedfiles: Language.ycp

      Yast.include self, "testsuite.rb"

      @READ = {
        "target" => { "bash_output" => {}, "size" => 1, "yast2" => {} }
      }

      TESTSUITE_INIT([@READ, {}, @READ], nil)

      @R = { "target" => { "string" => "", "stat" => {} } }

      Yast.import "Language"

      # not present	-> complete
      TEST(lambda { Language.IncompleteTranslation("en_US") }, [@R, {}, {}], nil)

      # incomplete
      Ops.set(@R, ["target", "string"], "50")
      Ops.set(@R, ["target", "stat"], { 1 => 2 })
      TEST(lambda { Language.IncompleteTranslation("en_GB") }, [@R, {}, {}], nil)

      # no SCR call, cached from previous
      TEST(lambda { Language.IncompleteTranslation("en_GB") }, [@R, {}, {}], nil)

      # complete
      Ops.set(@R, ["target", "string"], "99")
      TEST(lambda { Language.IncompleteTranslation("de_DE") }, [@R, {}, {}], nil)

      nil
    end
  end
end

Yast::IncompleteTranslationClient.new.main

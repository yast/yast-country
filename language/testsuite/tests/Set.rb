# encoding: utf-8

# tests for Language::Set
# Author:	jsuchome@suse.cz
# $Id$
module Yast
  class SetClient < Client
    def main
      # testedfiles: Language.ycp

      Yast.include self, "testsuite.rb"

      @READ = {
        "sysconfig" => { "language" => { "RC_LANG" => "en_US.UTF-8" } },
        "target"    => { "bash_output" => {}, "size" => 1, "yast2" => {} }
      }

      TESTSUITE_INIT([@READ, {}, @READ], nil)

      Yast.import "Language"

      @R = {
        "target" => {
          "dir"   => ["language_de_DE.ycp"],
          "yast2" => {
            "de_DE" => ["Deutsch", "Deutsch", ".UTF-8", "@euro", "German"]
          }
        }
      }

      TEST(lambda { Language.GetLocaleString(Language.language) }, [@R, {}, {}], nil)

      @EX = { "target" => { "bash_output" => {} } }

      TEST(lambda { Language.Set("de_DE") }, [{}, {}, @EX], nil)

      TEST(lambda { Language.GetLocaleString(Language.language) }, [], nil)

      @expert = { "use_utf8" => false }
      TEST(lambda { Language.SetExpertValues(@expert) }, [], nil)
      TEST(lambda { Language.GetLocaleString(Language.language) }, [], nil)

      nil
    end
  end
end

Yast::SetClient.new.main

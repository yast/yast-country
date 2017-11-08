# encoding: utf-8

# tests for Language::Save
# Author:	jsuchome@suse.cz
# $Id$
module Yast
  class SaveClient < Client
    def main
      # testedfiles: Language.ycp

      Yast.include self, "testsuite.rb"

      @READ = {
        "sysconfig" => {
          "language" => { "RC_LANG" => "en_US.UTF-8", "RC_LC_MESSAGES" => "" }
        },
        "target"    => {
          "bash_output" => {"exit" => 0},
          "size"        => 1,
          "yast2"       => {},
          "dir"         => []
        }
      }

      TESTSUITE_INIT([@READ, {}, @READ], nil)

      Yast.import "Language"

      Language.languages = "en_US"

      TEST(lambda { Language.Save }, [@READ, {}, @READ], nil)

      nil
    end
  end
end

Yast::SaveClient.new.main

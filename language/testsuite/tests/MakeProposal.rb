# encoding: utf-8

# tests for Language::MakeProposal
# Author:	jsuchome@suse.cz
# $Id$
module Yast
  class MakeProposalClient < Client
    def main
      # testedfiles: Language.ycp

      Yast.include self, "testsuite.rb"

      @READ = {
        "sysconfig" => {
          "language" => {
            "RC_LANG"             => "en_US.UTF-8",
            "INSTALLED_LANGUAGES" => "en_US,de_DE"
          }
        },
        "target"    => {
          "bash_output" => {},
          "size"        => 1,
          "dir"         => ["language_de_DE.ycp"],
          "yast2"       => {
            "de_DE" => ["Deutsch", "Deutsch", ".UTF-8", "@euro", "German"]
          }
        }
      }

      TESTSUITE_INIT([@READ, {}, @READ], nil)

      Yast.import "Language"

      TEST(lambda { Language.MakeProposal(false, false) }, [@READ, {}, {}], [])

      Language.languages = "en_US"

      TEST(lambda { Language.MakeProposal(true, false) }, [@READ, {}, {}], [])

      nil
    end
  end
end

Yast::MakeProposalClient.new.main

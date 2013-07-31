# encoding: utf-8

# tests for Keyboard::MakeProposal
# Author:	jsuchome@suse.cz
# $Id$
module Yast
  class MakeProposalClient < Client
    def main
      # testedfiles: Keyboard.ycp

      Yast.include self, "testsuite.rb"

      @READ = {
        "sysconfig" => {
          "keyboard" => { "YAST_KEYBOARD" => "czech-qwerty,pc104" }
        },
        "target"    => {
          "size"   => 1,
          "yast2"  => {
            "czech-qwerty" => [
              "Czech (qwerty)",
              {
                "pc104" => {
                  "ncurses" => "cz-lat2-us.map.gz",
                  "compose" => "latin2"
                }
              }
            ]
          },
          "tmpdir" => "/tmp",
          "ycp"    => {}
        },
        "probe"     => { "architecture" => "i386" }
      }
      @EXECUTE = { "target" => { "bash_output" => {} } }

      TESTSUITE_INIT([@READ, {}, @EXECUTE], nil)

      Yast.import "Keyboard"

      @R = {
        "target" => {
          "yast2" => {
            "czech-qwerty" => [
              "Czech (qwerty)",
              { "i386" => { "pc104" => { "ncurses" => "cz-lat2-us.map.gz" } } }
            ]
          },
          "ycp"   => { "XkbLayout" => "cz_qwerty,us" }
        }
      }

      DUMP("-----------------------------------")
      TEST(lambda { Keyboard.MakeProposal(true, false) }, [@R, {}, {}], [])

      nil
    end
  end
end

Yast::MakeProposalClient.new.main

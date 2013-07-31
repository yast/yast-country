# encoding: utf-8

# tests for Keyboard.ycp constructor
# Author: jsuchome@suse.cz
# $Id$
module Yast
  class KeyboardClient < Client
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
          "ycp"    => { "XkbLayout" => "cz_qwerty,us" }
        },
        "probe"     => { "architecture" => "i386" }
      }
      @EXECUTE = { "target" => { "bash_output" => {} } }

      TESTSUITE_INIT([@READ, {}, @EXECUTE], nil)

      Yast.import "Keyboard"

      nil
    end
  end
end

Yast::KeyboardClient.new.main

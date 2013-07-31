# encoding: utf-8

# Test for Keyboard.ycp constructor behaviour in "installation"
# Simulate that "dk" keyboard was set in linuxrc: see bug #118571
#
# Author:	Jiri Suchomel <jsuchome@suse.cz>
# $Id$
module Yast
  class ProbeClient < Client
    def main
      # testedfiles: Keyboard.ycp

      Yast.import "Testsuite"

      @READ = {
        "sysconfig" => {
          "keyboard" => { "YAST_KEYBOARD" => "czech-qwerty,pc104" }
        },
        "target"    => {
          "size"   => 1,
          "dir"    => [],
          "yast2"  => {
            "czech-qwerty" => [
              "Czech (qwerty)",
              {
                "pc104" => {
                  "ncurses" => "cz-lat2-us.map.gz",
                  "compose" => "latin2"
                }
              }
            ],
            "danish"       => [
              "Danish",
              { "pc104" => { "ncurses" => "dk-latin1.map.gz" } }
            ]
          },
          "tmpdir" => "/tmp",
          "ycp"    => { "XkbLayout" => "cz_qwerty,us" },
          "string" => ""
        },
        "probe"     => { "architecture" => "i386" },
        "etc"       => { "install_inf" => { "Keytable" => "dk" } }
      }
      @EXECUTE = { "target" => { "bash_output" => {} } }

      Testsuite.Init([@READ, {}, @EXECUTE], nil)

      Yast.import "Stage"

      Stage.Set("initial")

      Yast.import "Keyboard"

      nil
    end
  end
end

Yast::ProbeClient.new.main

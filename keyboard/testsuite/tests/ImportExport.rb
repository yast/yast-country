# encoding: utf-8

# tests for Keyboard.ycp autoyast functions
# Author:	jsuchome@suse.cz
# $Id$
module Yast
  class ImportExportClient < Client
    def main
      # testedfiles: Keyboard.ycp

      Yast.import "Testsuite"

      @READ = {
        "target" => {
          "size"  => 1,
          "dir"   => [],
          "yast2" => {
            "czech-qwerty" => [
              "Czech (qwerty)",
              {
                "pc104" => {
                  "ncurses" => "cz-lat2-us.map.gz",
                  "compose" => "latin2"
                }
              }
            ]
          }
        },
        "probe"  => { "architecture" => "i386" }
      }

      @E = { "target" => { "bash_output" => {} } }

      Yast.import "Mode"

      # let's simulate Mode::config
      Mode.SetMode("autoinst_config")

      Testsuite.Init([@READ, {}, @E], nil)

      Yast.import "Keyboard"

      Testsuite.Test(lambda { Keyboard.Modified }, [], nil)

      @imported = { "keymap" => "czech-qwerty" }

      Testsuite.Test(lambda { Keyboard.Import(@imported) }, [@READ, {}, @E], nil)

      Testsuite.Test(lambda { Keyboard.Modified }, [], nil)

      Testsuite.Test(lambda { Keyboard.Export }, [], nil)

      Testsuite.Test(lambda { Keyboard.Summary }, [], nil)

      nil
    end
  end
end

Yast::ImportExportClient.new.main

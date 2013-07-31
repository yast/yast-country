# encoding: utf-8

# tests for Keyboard.ycp autoyast functions
# Author:	jsuchome@suse.cz
# $Id$
module Yast
  class ReadExportClient < Client
    def main
      # testedfiles: Keyboard.ycp

      Yast.import "Testsuite"

      @READ = {
        "sysconfig" => {
          "keyboard" => { "YAST_KEYBOARD" => "english-us,pc104" }
        },
        "target"    => {
          "size"   => 1,
          "dir"    => [],
          "yast2"  => {
            "english-us" => [
              "English (US)",
              { "pc104" => { "ncurses" => "us.map.gz" } }
            ]
          },
          "tmpdir" => "/tmp"
        },
        "probe"     => { "architecture" => "i386" }
      }

      @E = { "target" => { "bash_output" => {} } }

      Yast.import "Mode"

      # let's simulate Mode::config
      Mode.SetMode("autoinst_config")

      Testsuite.Init([@READ, {}, @E], nil)

      Yast.import "Keyboard"

      Testsuite.Test(lambda { Keyboard.Restore }, [@READ, {}, @E], nil)

      Testsuite.Test(lambda { Keyboard.Read }, [], nil)

      Testsuite.Test(lambda { Keyboard.Export }, [], nil)

      Testsuite.Test(lambda { Keyboard.Summary }, [], nil)

      Testsuite.Test(lambda { Keyboard.Modified }, [], nil)

      nil
    end
  end
end

Yast::ReadExportClient.new.main

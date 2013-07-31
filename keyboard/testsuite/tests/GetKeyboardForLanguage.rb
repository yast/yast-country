# encoding: utf-8

# tests for Keyboard::GetKeyboardForLanguage
# Author: jsuchome@suse.cz
# $Id$
module Yast
  class GetKeyboardForLanguageClient < Client
    def main
      # testedfiles: Keyboard.ycp

      Yast.include self, "testsuite.rb"

      @READ = {
        "sysconfig" => {
          "keyboard" => { "YAST_KEYBOARD" => "czech-qwerty,pc104" }
        },
        "target"    => {
          "size"   => 1,
          "yast2"  => {},
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
            "en_US" => "english-us",
            "cs_CZ" => "czech",
            "de_CH" => "german-ch"
          }
        }
      }

      TEST(lambda { Keyboard.GetKeyboardForLanguage("en_US", "en_US") }, [
        @R,
        {},
        {}
      ], [])

      TEST(lambda { Keyboard.GetKeyboardForLanguage("cs_CZ", "en_US") }, [
        @R,
        {},
        {}
      ], [])

      TEST(lambda { Keyboard.GetKeyboardForLanguage("de_CH", "en_US") }, [
        @R,
        {},
        {}
      ], [])

      TEST(lambda { Keyboard.GetKeyboardForLanguage("de_DE", "en_US") }, [
        @R,
        {},
        {}
      ], [])

      nil
    end
  end
end

Yast::GetKeyboardForLanguageClient.new.main

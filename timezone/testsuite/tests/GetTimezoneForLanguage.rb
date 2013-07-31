# encoding: utf-8

# tests for Timezone::GetTimezoneForLanguage
# Author: jsuchome@suse.cz
# $Id$
module Yast
  class GetTimezoneForLanguageClient < Client
    def main
      # testedfiles: Timezone.ycp

      Yast.include self, "testsuite.rb"

      @READ = {
        "sysconfig" => {
          "clock" => { "TIMEZONE" => "Europe/Prague", "HWCLOCK" => "-u" }
        },
        "target"    => { "size" => 1, "yast2" => {} },
        "etc"       => { "adjtime" => ["0", "0", "UTC"] }
      }
      @EXECUTE = { "target" => { "bash_output" => {} } }

      TESTSUITE_INIT([@READ, {}, @EXECUTE], nil)

      Yast.import "Timezone"

      @R = {
        "target" => {
          "yast2" => { "en_US" => "US/Mountain", "cs_CZ" => "Europe/Prague" }
        }
      }

      TEST(lambda { Timezone.GetTimezoneForLanguage("en_US", "US/Pacific") }, [
        @R,
        {},
        {}
      ], [])

      TEST(lambda { Timezone.GetTimezoneForLanguage("de_DE", "US/Pacific") }, [
        @R,
        {},
        {}
      ], [])

      nil
    end
  end
end

Yast::GetTimezoneForLanguageClient.new.main

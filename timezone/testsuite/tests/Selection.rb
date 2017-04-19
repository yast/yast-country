# encoding: utf-8

# tests for Timezone::Selection and Timezone::Set functions
# Author: jsuchome@suse.cz
# $Id$
module Yast
  class SelectionClient < Client
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
          "yast2" => [
            {
              "name"    => "Europe",
              "entries" => {
                "Europe/Berlin" => "Germany",
                "Europe/Prague" => "Czechia"
              }
            },
            { "name" => "USA", "entries" => { "US/Mountain" => "Mountain" } }
          ]
        }
      }

      TEST(lambda { Timezone.Selection(1) }, [@R, {}, {}], [])

      @sel = Convert.to_integer(TEST(lambda do
        Timezone.Set("Europe/Prague", false)
      end, [
        @R,
        {},
        {}
      ], []))

      TEST(lambda { Timezone.Selection(@sel) }, [@R, {}, {}], [])

      @sel = Convert.to_integer(TEST(lambda { Timezone.Set("US/Pacific", false) }, [
        @R,
        {},
        {}
      ], []))

      TEST(lambda { Timezone.Selection(@sel) }, [@R, {}, {}], [])

      nil
    end
  end
end

Yast::SelectionClient.new.main

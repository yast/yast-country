# encoding: utf-8

# tests for Timezone::MakeProposal
# Author:	jsuchome@suse.cz
# $Id$
module Yast
  class MakeProposalClient < Client
    def main
      # testedfiles: Timezone.ycp

      Yast.include self, "testsuite.rb"

      @READ = {
        "sysconfig" => {
          "clock" => {
            "TIMEZONE"         => "Europe/Prague",
            "DEFAULT_TIMEZONE" => "Europe/Prague",
            "HWCLOCK"          => "-u"
          }
        },
        "target"    => { "size" => 1, "yast2" => {} },
        "etc"       => { "adjtime" => ["0", "0", "UTC"] }
      }
      @EXECUTE = { "target" => { "bash_output" => {} } }

      TESTSUITE_INIT([@READ, {}, @EXECUTE], nil)

      Yast.import "Timezone"

      @R = {
        "probe"  => { "architecture" => "i386", "is_vmware" => false },
        "target" => {
          "yast2" => [
            {
              "name"    => "Europe",
              "entries" => {
                "Europe/Berlin" => "Germany",
                "Europe/Prague" => "Czechia"
              }
            }
          ]
        }
      }
      @E = { "target" => { "bash_output" => {} } }

      TEST(lambda { Timezone.MakeProposal(true, false) }, [@R, {}, @E], [])

      nil
    end
  end
end

Yast::MakeProposalClient.new.main

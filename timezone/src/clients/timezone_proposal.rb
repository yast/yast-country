# encoding: utf-8

# File:		timezone_proposal.rb
#
# Author:		Klaus Kaempf <kkaempf@suse.de>
#
# Purpose:		Proposal function dispatcher - timezone.
#
#			See also file proposal-API.txt for details.
module Yast
  class TimezoneProposalClient < Client
    def main
      Yast.import "UI"
      textdomain "country"

      Yast.import "Timezone"
      Yast.import "Wizard"

      Yast.include self, "timezone/dialogs.rb"

      @func = Convert.to_string(WFM.Args(0))
      @param = Convert.to_map(WFM.Args(1))
      @ret = {}

      if @func == "MakeProposal"
        @force_reset = Ops.get_boolean(@param, "force_reset", false)
        @language_changed = Ops.get_boolean(@param, "language_changed", false)

        if Time.now < File.stat(__FILE__).mtime
          Ops.set(@ret, "raw_proposal", [])
          @m2 = Convert.to_map(
            SCR.Execute(path(".target.bash_output"), "/bin/date")
          )
          # error text, %1 is output of 'date' command
          Ops.set(
            @ret,
            "warning",
            Builtins.sformat(
              _(
                "Time %1 is in the past.\nSet a correct time before starting installation."
              ),
              Ops.get_string(@m2, "stdout", "")
            )
          )
          Ops.set(@ret, "warning_level", :blocker)
        else
          Yast.import "Storage"
          if !Timezone.windows_partition &&
              Ops.greater_than(
                Builtins.size(
                  Storage.GetWinPrimPartitions(Storage.GetTargetMap)
                ),
                0
              )
            Timezone.windows_partition = true
            Builtins.y2milestone("windows partition found: assuming local time")
          end

          # Fill return map
          @ret = {
            "raw_proposal"     => Timezone.MakeProposal(
              @force_reset,
              @language_changed
            ),
            "language_changed" => false
          }
        end
      elsif @func == "AskUser"
        Wizard.OpenAcceptDialog

        @result = TimezoneDialog(
          { "enable_next" => Ops.get_boolean(@param, "has_next", false) }
        )
        Wizard.CloseDialog

        # Fill return map
        @ret = { "workflow_sequence" => @result, "language_changed" => false }
      elsif @func == "Description"
        # Fill return map.
        #
        # Static values do just nicely here, no need to call a function.

        @ret = {
          # summary item
          "rich_text_title" => _("Time Zone"),
          # menue label text
          "menu_title"      => _("&Time Zone"),
          "id"              => "timezone_stuff"
        }
      end

      deep_copy(@ret)
    end
  end
end

Yast::TimezoneProposalClient.new.main

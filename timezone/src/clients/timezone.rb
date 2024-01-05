# ------------------------------------------------------------------------------
# Copyright (c) 2012 Novell, Inc. All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------
#
# Module:             timezone.ycp
#
# Author:             Klaus Kaempf (kkaempf@suse.de)
#
# Submodules:
#
#
# Purpose:	configure timezone in running system
#
# Modify:
#
#
# $Id$
module Yast
  class TimezoneClient < Client
    def main
      Yast.import "UI"
      textdomain "country"

      Yast.import "CommandLine"
      Yast.import "Timezone"
      Yast.import "Wizard"

      Yast.include self, "timezone/dialogs.rb"

      # -- the command line description map --------------------------------------
      @cmdline = {
        "id"         => "timezone",
        # translators: command line help text for timezone module
        "help"       => _(
          "Time zone configuration"
        ),
        "guihandler" => fun_ref(method(:TimezoneSequence), "any ()"),
        "initialize" => fun_ref(method(:TimezoneRead), "boolean ()"),
        "finish"     => fun_ref(method(:TimezoneWrite), "boolean ()"),
        "actions"    => {
          "summary" => {
            "handler"  => fun_ref(
              method(:TimezoneSummaryHandler),
              "boolean (map)"
            ),
            # command line help text for 'summary' action
            "help"     => _(
              "Time zone configuration summary"
            ),
            "readonly" => true
          },
          "set"     => {
            "handler" => fun_ref(method(:TimezoneSetHandler), "boolean (map)"),
            # command line help text for 'set' action
            "help"    => _(
              "Set new values for time zone configuration"
            )
          },
          "list"    => {
            "handler"  => fun_ref(method(:TimezoneListHandler), "boolean (map)"),
            # command line help text for 'list' action
            "help"     => _(
              "List all available time zones"
            ),
            "readonly" => true
          }
        },
        "options"    => {
          "timezone" => {
            # command line help text for 'set timezone' option
            "help" => _(
              "New time zone"
            ),
            "type" => "string"
          },
          "hwclock"  => {
            # command line help text for 'set hwclock' option
            "help"     => _(
              "New value for hardware clock. Can be 'local', 'utc' or 'UTC'."
            ),
            "type"     => "enum",
            "typespec" => ["local", "utc", "UTC"]
          }
        },
        "mappings"   => {
          "summary" => [],
          "set"     => ["timezone", "hwclock"],
          "list"    => []
        }
      }

      CommandLine.Run(@cmdline)
    end

    # read timezone settings (store initial values)
    def TimezoneRead
      Timezone.PushVal
      true
    end

    # write timezone settings
    def TimezoneWrite
      if Timezone.Modified
        Builtins.y2milestone(
          "User selected new timezone/clock setting: <%1> <%2>",
          Timezone.timezone,
          Timezone.hwclock
        )

        Timezone.Save
      else
        Builtins.y2milestone("Timezone not changed --> doing nothing")
      end
      true
    end

    # the timezone configuration sequence
    def TimezoneSequence
      # create the wizard dialog
      Wizard.OpenOKDialog

      if Timezone.system_has_windows?
        Timezone.windows_partition = true
        Builtins.y2milestone("windows partition found")
      end

      result = TimezoneDialog({})

      if result == :next
        TimezoneWrite() # `cancel or `back
      else
        Builtins.y2milestone("User cancelled --> no change")
      end
      Wizard.CloseDialog
      deep_copy(result)
    end

    # Handler for timezone summary
    def TimezoneSummaryHandler(options)
      options = deep_copy(options)
      # summary label
      CommandLine.Print(
        Builtins.sformat(_("Current Time Zone:\t%1"), Timezone.timezone)
      )

      if !Timezone.utc_only
        # summary label
        CommandLine.Print(
# summary text (Clock setting)
Builtins.sformat(
  _("Hardware Clock Set To:\t%1"),
  # summary text (Clock setting)
  (Timezone.hwclock == "-u") ? _("UTC") : _("Local time")
)
)
      end
      # summary label
      CommandLine.Print(
        Builtins.sformat(
          _("Current Time and Date:\t%1"),
          Timezone.GetDateTime(true, true)
        )
      )
      true
    end

    # Handler for listing timezone layouts
    def TimezoneListHandler(options)
      options = deep_copy(options)
      Builtins.foreach(Timezone.get_zonemap) do |zone|
        CommandLine.Print("")
        # summary label
        CommandLine.Print(
          Builtins.sformat("Region: %1", Ops.get_string(zone, "name", ""))
        )
        Builtins.foreach(Ops.get_map(zone, "entries", {})) do |code, name|
          CommandLine.Print(Builtins.sformat("%1 (%2)", code, name))
        end
      end
      true
    end

    # Handler for changing timezone settings
    def TimezoneSetHandler(options)
      options = deep_copy(options)
      timezone = Ops.get_string(options, "timezone", "")
      hwclock = Ops.get_string(options, "hwclock", "")

      Timezone.Set(timezone, true) if timezone != ""
      if hwclock != "" && !Timezone.utc_only
        Timezone.hwclock = (Builtins.tolower(hwclock) == "utc") ? "-u" : "--localtime"
      end
      Timezone.Modified
    end
  end
end

Yast::TimezoneClient.new.main

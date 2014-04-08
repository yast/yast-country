# encoding: utf-8

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
# Client for initial timezone setting (part of installation sequence)
# Author:	Jiri Suchomel <jsuchome@suse.cz>
# $Id$
module Yast
  class InstTimezoneClient < Client
    def main
      Yast.import "UI"
      Yast.import "GetInstArgs"
      Yast.import "Mode"
      Yast.import "Storage"
      Yast.import "Wizard"

      Yast.include self, "timezone/dialogs.rb"

      @args = GetInstArgs.argmap
      @args["first_run"] = "yes" unless @args["first_run"] == "no"

      if Stage.initial &&
          Ops.greater_than(
            Builtins.size(Storage.GetWinPrimPartitions(Storage.GetTargetMap)),
            0
          )
        Timezone.windows_partition = true
        Builtins.y2milestone("windows partition found: assuming local time")
      end

      full_size_timezone_dialog
    end

    # While the rest of the installation dialogs have enough room
    # to have the title on the left (bnc#868859), this one needs the space
    # for the world map.
    # Disable the left-title by requesting space for Steps, but shrink
    # it by not adding any steps :-)
    def full_size_timezone_dialog
      Wizard.OpenNextBackStepsDialog

      Wizard.HideAbortButton if Mode.mode == "firstboot"

      TimezoneDialog(@args)
    ensure
      Wizard.CloseDialog
    end
  end
end

Yast::InstTimezoneClient.new.main

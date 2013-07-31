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

      if Ops.get_string(@args, "first_run", "yes") != "no"
        Ops.set(@args, "first_run", "yes")
      end

      Wizard.HideAbortButton if Mode.mode == "firstboot"

      if Stage.initial &&
          Ops.greater_than(
            Builtins.size(Storage.GetWinPrimPartitions(Storage.GetTargetMap)),
            0
          )
        Timezone.windows_partition = true
        Builtins.y2milestone("windows partition found: assuming local time")
      end

      TimezoneDialog(@args)
    end
  end
end

Yast::InstTimezoneClient.new.main

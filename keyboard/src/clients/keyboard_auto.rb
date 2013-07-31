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

# Autoinstallation client for keyboard setting
# Author	: Jiri Suchomel <jsuchome@suse.cz>
#
# $Id$
module Yast
  class KeyboardAutoClient < Client
    def main
      Yast.import "UI"
      Yast.import "Arch"
      Yast.import "Keyboard"
      Yast.import "Wizard"

      Yast.include self, "keyboard/dialogs.rb"

      @ret = nil
      @func = ""
      @param = {}

      if Ops.greater_than(Builtins.size(WFM.Args), 0) &&
          Ops.is_string?(WFM.Args(0))
        @func = Convert.to_string(WFM.Args(0))
        if Ops.greater_than(Builtins.size(WFM.Args), 1) &&
            Ops.is_map?(WFM.Args(1))
          @param = Convert.convert(
            WFM.Args(1),
            :from => "any",
            :to   => "map <string, any>"
          )
        end
      end

      Builtins.y2debug("func=%1", @func)
      Builtins.y2debug("param=%1", @param)

      if @func == "Change" && !Arch.s390
        Wizard.CreateDialog
        Wizard.HideAbortButton

        @ret = KeyboardDialog({})

        Wizard.CloseDialog
      elsif @func == "Import"
        @ret = Keyboard.Import(@param)
      elsif @func == "Summary"
        @ret = Keyboard.Summary
      elsif @func == "Reset"
        Keyboard.Import(
          {
            "keymap"          => Keyboard.keyboard_on_entry,
            "keyboard_values" => Keyboard.expert_on_entry
          }
        )
        Keyboard.ExpertSettingsChanged = false
        @ret = {}
      elsif @func == "Read"
        # If we would need reading from system in Mode::config, Restore is necessary
        Keyboard.Restore if Mode.config
        @ret = Keyboard.Read
      elsif @func == "Export"
        @ret = Keyboard.Export
      elsif @func == "Write"
        @ret = Keyboard.Save
      # Return if configuration  was changed
      # return boolean
      elsif @func == "GetModified"
        @ret = Keyboard.Modified
      # Set all modified flags
      # return boolean
      elsif @func == "SetModified"
        Keyboard.ExpertSettingsChanged = true # hook (no general 'modified' variable)
        @ret = true
      end

      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("keyboard auto finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret)
    end
  end
end

Yast::KeyboardAutoClient.new.main

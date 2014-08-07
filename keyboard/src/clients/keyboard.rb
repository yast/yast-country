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

#
# Module:             keyboard.ycp
#
# Author:             Thomas Roelz (tom@suse.de)
#
# Submodules:
#
#
# Purpose:	configure keyboard in running system
#
# Modify:
#
#
# $Id$
module Yast
  class KeyboardClient < Client
    def main
      Yast.import "UI"
      textdomain "country"

      Yast.import "Arch"
      Yast.import "CommandLine"
      Yast.import "Confirm"
      Yast.import "Keyboard"
      Yast.import "Popup"
      Yast.import "Message"
      Yast.import "Service"
      Yast.import "Stage"
      Yast.import "Wizard"

      Yast.include self, "keyboard/dialogs.rb"


      # -- the command line description map --------------------------------------
      @cmdline = {
        "id"         => "keyboard",
        # translators: command line help text for Securoty module
        "help"       => _(
          "Keyboard configuration."
        ),
        "guihandler" => fun_ref(method(:KeyboardSequence), "any ()"),
        "initialize" => fun_ref(method(:KeyboardRead), "boolean ()"),
        "finish"     => fun_ref(method(:KeyboardWrite), "boolean ()"),
        "actions"    => {
          "summary" => {
            "handler" => fun_ref(
              method(:KeyboardSummaryHandler),
              "boolean (map)"
            ),
            # command line help text for 'summary' action
            "help"    => _(
              "Keyboard configuration summary."
            )
          },
          "set"     => {
            "handler" => fun_ref(method(:KeyboardSetHandler), "boolean (map)"),
            # command line help text for 'set' action
            "help"    => _(
              "Set new values for keyboard configuration."
            )
          },
          "list"    => {
            "handler" => fun_ref(method(:KeyboardListHandler), "boolean (map)"),
            # command line help text for 'list' action
            "help"    => _(
              "List all available keyboard layouts."
            )
          }
        },
        "options"    => {
          "layout" => {
            # command line help text for 'set layout' option
            "help" => _(
              "New keyboard layout"
            ),
            "type" => "string"
          }
        },
        "mappings"   => { "summary" => [], "set" => ["layout"], "list" => [] }
      }

      CommandLine.Run(@cmdline)
      true
    end

    # read keyboard settings
    def KeyboardRead
      Keyboard.Read
      # Check if this is a reconfiguration run.
      #
      if Stage.reprobe
        # Reprobe keyboard module to achieve same behaviour as
        # during installation.
        Keyboard.Probe
        Keyboard.SetConsole(Keyboard.current_kbd)
        Keyboard.SetX11(Keyboard.current_kbd)

        Builtins.y2milestone("Reprobed keyboard")
      end
      true
    end

    # write keyboard settings
    def KeyboardWrite
      if Keyboard.needs_new_initrd?
        Popup.ShowFeedback(Message.updating_configuration, Message.takes_a_while)
      end
      Keyboard.Save
      Service.Restart("kbd")
      Popup.ClearFeedback if Keyboard.needs_new_initrd?
      true
    end

    # the keyboard configuration sequence
    def KeyboardSequence
      # dont ask for keyboard on S/390
      return :next if Arch.s390

      KeyboardRead()

      Wizard.OpenOKDialog

      result = KeyboardDialog({})

      if result == :next
        KeyboardWrite()
      else
        Builtins.y2milestone("User cancelled --> no change")
      end
      Wizard.CloseDialog
      result
    end

    # Handler for keyboard summary
    def KeyboardSummaryHandler(options)
      options = deep_copy(options)
      # summary label
      CommandLine.Print(
        Builtins.sformat(_("Current Keyboard Layout: %1"), Keyboard.current_kbd)
      )
      false
    end

    # Handler for listing keyboard layouts
    def KeyboardListHandler(options)
      options = deep_copy(options)
      Builtins.foreach(Keyboard.Selection) do |code, name|
        CommandLine.Print(Builtins.sformat("%1 (%2)", code, name))
      end
      false
    end


    # Handler for changing keyboard settings
    def KeyboardSetHandler(options)
      options = deep_copy(options)
      keyboard = Ops.get_string(options, "layout", "")

      if keyboard == "" || !Builtins.haskey(Keyboard.Selection, keyboard)
        # error message (%1 is given layout); do not translate 'list'
        CommandLine.Print(
          Builtins.sformat(
            _(
              "Keyboard layout '%1' is invalid. Use a 'list' command to see possible values."
            ),
            keyboard
          )
        )
      end
      Keyboard.Set(keyboard)

      Keyboard.Modified
    end
  end
end

Yast::KeyboardClient.new.main

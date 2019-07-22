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

# File:
#	keyboard/dialogs.ycp
#
# Authors:
#	Klaus   Kämpf <kkaempf@suse.de>
#	Michael Hager <mike@suse.de>
#	Stefan  Hundhammer <sh@suse.de>
#
# Summary:
#	Dialogs for keyboard configuration
#
# $Id$
module Yast
  module KeyboardDialogsInclude
    def initialize_keyboard_dialogs(include_target)
      Yast.import "UI"
      textdomain "country"

      Yast.import "Keyboard"
      Yast.import "Label"
      Yast.import "Mode"
      Yast.import "Popup"
      Yast.import "Stage"
      Yast.import "Wizard"
    end

    # Dialog with expert keyboard configuration
    def KeyboardExpertDialog
      ret = :none
      # help text for keyboard expert screen
      help_text = _(
        "<p>\n" +
          "Here, fine tune various settings of the keyboard module.\n" +
          "These settings are written into the file <tt>/etc/sysconfig/keyboard</tt>.\n" +
          "If unsure, use the default values already selected.\n" +
          "</p>"
      ) +
        # help text for keyboard expert screen cont.
        _(
          "<p>Settings made here apply only to the console keyboard. Configure the keyboard for the graphical user interface with another tool.</p>\n"
        )


      # label text

      UI.OpenDialog(
        Opt(:decorated),
        HBox(
          HWeight(30, RichText(help_text)),
          HStretch(),
          HSpacing(1),
          HWeight(
            70,
            VBox(
              HSpacing(60),
              # heading text
              Heading(_("Expert Keyboard Settings")),
              VSpacing(Opt(:vstretch), 1),
              Left(
                InputField(
                  Id(:rate),
                  Opt(:hstretch),
                  # label text
                  _("Repeat &Rate")
                )
              ),
              Left(
                InputField(
                  Id(:delay),
                  Opt(:hstretch),
                  # label text
                  _("De&lay before Repetition Starts")
                )
              ),
              VSpacing(Opt(:vstretch), 1),
              Frame(
                # frame label
                _("Start-Up States"),
                VBox(
                  Left(
                    ComboBox(
                      # combobox label
                      Id(:numlock),
                      _("&Num Lock On"),
                      [
                        # combobox item
                        Item(Id("bios"), _("BIOS Settings")),
                        # combobox item
                        Item(Id("yes"), _("Yes")),
                        # combobox item
                        Item(Id("no"), _("No")),
                        # combobox item
                        Item(Id("untouched"), _("<Untouched>"))
                      ]
                    )
                  ),
                  VSpacing(Opt(:vstretch), 1)
                )
              ),
              VSpacing(Opt(:vstretch), 1),
              VSpacing(Opt(:vstretch), 1),
              Left(
                # label text
                CheckBox(Id(:discaps), _("D&isable Caps Lock"))
              ),
              VSpacing(1),
              VStretch(),
              ButtonBox(
                PushButton(Id(:ok), Opt(:default), Label.OKButton),
                PushButton(Id(:cancel), Label.CancelButton)
              ),
              VSpacing(0.5)
            )
          ),
          HSpacing(1)
        )
      )
      val = Keyboard.GetExpertValues
      val_on_entry = deep_copy(val)
      Builtins.y2milestone("map %1", val)
      UI.ChangeWidget(Id(:rate), :Value, Ops.get_string(val, "rate", ""))
      UI.ChangeWidget(Id(:rate), :ValidChars, "0123456789.")
      UI.ChangeWidget(Id(:delay), :Value, Ops.get_string(val, "delay", ""))
      UI.ChangeWidget(Id(:delay), :ValidChars, "0123456789")
      tmp = Ops.get_string(val, "numlock", "")
      tmp = "untouched" if tmp == ""
      UI.ChangeWidget(Id(:numlock), :Value, tmp)
      UI.ChangeWidget(
        Id(:discaps),
        :Value,
        Ops.get_boolean(val, "discaps", false)
      )
      begin
        ret = Convert.to_symbol(UI.UserInput)
        if ret == :ok
          val = {}
          Ops.set(val, "rate", UI.QueryWidget(Id(:rate), :Value))
          Ops.set(val, "delay", UI.QueryWidget(Id(:delay), :Value))
          Ops.set(val, "numlock", "")
          tmp = Convert.to_string(UI.QueryWidget(Id(:numlock), :Value))
          Builtins.y2milestone("tmp %1", tmp)
          if Builtins.contains(["bios", "yes", "no"], tmp)
            Ops.set(val, "numlock", tmp)
          end
          Ops.set(val, "discaps", UI.QueryWidget(Id(:discaps), :Value))
          Builtins.y2milestone("map ok %1", val)
          Keyboard.SetExpertValues(val)
        end
      end until ret == :cancel || ret == :ok
      UI.CloseDialog

      nil
    end

    # main dialog for choosing keyboard
    # @param [Hash] args: arguments forwarded from the initial client call
    # (checking for "enable_back" and "enable_next" keys)
    def KeyboardDialog(args)
      args = deep_copy(args)
      keyboard = ""

      keyboardsel = SelectionBox(
        Id(:keyboard),
        Opt(:notify),
        # title for selection box 'keyboard layout'
        _("&Keyboard Layout"),
        Keyboard.GetKeyboardItems
      )

      # title for input field to test the keyboard setting
      # (no more than about 25 characters!)
      test = InputField(Opt(:hstretch), _("&Test"))
      test = Empty() if Mode.config

      # Put test widget below selection list.
      #
      keyboardsel = VBox(
        keyboardsel,
        test,
        VSpacing(0.8),
        # push button
        PushButton(Id(:expert), _("E&xpert Settings..."))
      )

      # ----------------------------------------------------------------------
      # Build dialog
      # ----------------------------------------------------------------------

      contents = VBox(
        HBox(
          HWeight(20, HStretch()),
          HWeight(50, keyboardsel),
          HWeight(20, HStretch())
        ),
        VSpacing()
      )

      # help text for keyboard screen (header)
      help_text = _("\n<p><big><b>Keyboard Configuration</b></big></p>")

      if Stage.initial || Stage.firstboot
        help_text = Ops.add(
          help_text,
          # help text for keyboard screen (installation)
          _(
            "<p>\n" +
              "Choose the <b>Keyboard Layout</b> to use for\n" +
              "installation and in the installed system.  \n" +
              "Test the layout in <b>Test</b>.\n" +
              "For advanced options, such as repeat rate and delay, select <b>Expert Settings</b>.\n" +
              "</p>\n"
          )
        )
        # general help trailer
        help_text = Ops.add(
          help_text,
          _(
            "<p>\n" +
              "If unsure, use the default values already selected.\n" +
              "</p>"
          )
        )
      else
        help_text = Ops.add(
          help_text,
          # help text for keyboard screen (installation)
          _(
            "<p>\n" +
              "Choose the <b>Keyboard Layout</b> to use in the system.\n" +
              "For advanced options, such as repeat rate and delay, select <b>Expert Settings</b>.</p>\n" +
              "<p>Find more options as well as more layouts in the keyboard layout tool of your desktop environment.</p>\n"
          )
        )
      end

      # Screen title for keyboard screen
      Wizard.SetContents(
        _("System Keyboard Configuration"),
        contents,
        help_text,
        Ops.get_boolean(args, "enable_back", true),
        Ops.get_boolean(args, "enable_next", true)
      )

      Wizard.SetDesktopTitleAndIcon("org.opensuse.yast.Keyboard")
      Wizard.SetTitleIcon("yast-keyboard") if Stage.initial || Stage.firstboot

      # Initially set the current keyboard to establish a consistent state.
      # Not on installed system, where it might clash with layout set different way
      Keyboard.Set(Keyboard.current_kbd) if Mode.installation

      UI.SetFocus(Id(:keyboard))

      ret = nil
      begin
        ret = Wizard.UserInput

        if ret == :abort && Popup.ConfirmAbort(:painless) && !Mode.config
          return :abort
        end
        ret = :next if ret == :ok

        KeyboardExpertDialog() if ret == :expert

        if ret == :next || ret == :keyboard
          # Get the selected keyboard.
          #
          keyboard = Convert.to_string(
            UI.QueryWidget(Id(:keyboard), :CurrentItem)
          )

          Builtins.y2milestone(
            "on entry %1 current %2 ret %3",
            Keyboard.keyboard_on_entry,
            Keyboard.current_kbd,
            keyboard
          )

          # Set it in Keyboard module.
          Keyboard.Set(keyboard) if Keyboard.current_kbd != keyboard

          if ret == :next && !Mode.config
            # User wants to keep his changes.
            # Set user_decision flag in keyboard module.
            #
            Keyboard.user_decision = true

            if Keyboard.Modified
              # User has chosen a different keyboard from the database.
              # ==> clear unique_key in the keyboard module to achieve
              # configured = no and needed = no in Keyboard::Save() for
              # _ALL_ keyboards.
              #
              Builtins.y2milestone(
                "Clearing unique key <%1> due to manual selection",
                Keyboard.unique_key
              )

              Keyboard.unique_key = ""
            end
          end
        end
      end until ret == :next || ret == :back || ret == :cancel

      if ret == :back || ret == :cancel
        Builtins.y2milestone(
          "`back or `cancel restoring: <%1>",
          Keyboard.keyboard_on_entry
        )

        # Reset keyboard to initial state.
        Keyboard.Set(Keyboard.keyboard_on_entry)
      end

      Convert.to_symbol(ret)
    end
  end
end

# Copyright (c) [2019] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

# File:
#   Keyboard.rb
#
# Module:
#   Keyboard
#
# Usage:
# ------
# This module provides the following data for public access via Keyboard::<var-name>.
#
#

require "yast"
require "shellwords"
require "y2keyboard/strategies/kb_strategy"

module Yast
  class KeyboardClass < Module
    include Yast::Logger

    def main
      Yast.import "UI"
      textdomain "country"

      Yast.import "Arch"
      Yast.import "AsciiFile"
      Yast.import "Directory"
      Yast.import "FileUtils"
      Yast.import "Initrd"
      Yast.import "Label"
      Yast.import "Language"
      Yast.import "Linuxrc"
      Yast.import "Misc"
      Yast.import "Mode"
      Yast.import "Package"
      Yast.import "OSRelease"
      Yast.import "ProductFeatures"
      Yast.import "Stage"
      Yast.import "Report"

      # general kb startegy which is used for temporary changes only.
      @kb_strategy = Y2Keyboard::Strategies::KbStrategy.new

      # The keyboard currently set.
      #
      @current_kbd = ""

      # keyboard set on start
      @keyboard_on_entry = ""

      # The default keyboard if set.
      #
      @default_kbd = ""

      # Flag indicating if the user has chosen a keyboard.
      # To be set from outside.
      #
      @user_decision = false

      # if Keyboard::Restore() was called
      @restore_called = false

      # User readable description, access via Keyboard::MakeProposal()
      #
      @name = ""

      Keyboard()
    end


    # Get the system_language --> keyboard_language conversion map.
    #
    # @return  conversion map
    #
    # @see #get_xkblayout2keyboard()

    def get_lang2keyboard
      base_lang2keyboard = Convert.to_map(
        SCR.Read(path(".target.yast2"), "lang2keyboard.ycp")
      )
      base_lang2keyboard = {} if base_lang2keyboard == nil

      Builtins.union(base_lang2keyboard, Language.GetLang2KeyboardMap(true))
    end


    # GetKeyboardForLanguage()
    #
    # Get the keyboard language for the given system language.
    #
    # @param	System language code, e.g. "en_US".
    #		Default keyboard language to be returned if nothing found.
    #
    # @return  The keyboard language for this language, e.g. "english-us"
    #		or the default value if nothing found.
    #
    def GetKeyboardForLanguage(sys_language, default_keyboard)
      lang2keyboard = get_lang2keyboard
      kb = Ops.get_string(lang2keyboard, sys_language, "")

      if kb == ""
        sys_language = Builtins.substring(sys_language, 0, 2)
        kb = Ops.get_string(lang2keyboard, sys_language, default_keyboard)
      end
      Builtins.y2milestone(
        "GetKeyboardForLanguage lang:%1 def:%2 ret:%3",
        sys_language,
        default_keyboard,
        kb
      )
      kb
    end

    # check if we are running in XEN (autorepeat functionality not supported)
    # seem bnc#376945, #371756
    def xen_running
      if @xen_is_running == nil
        @xen_is_running = Convert.to_boolean(SCR.Read(path(".probe.xen")))
      end
      @xen_is_running == true
    end


    # run X11 configuration after inital boot
    def x11_setup_needed
      Arch.x11_setup_needed &&
        !(Linuxrc.serial_console || Linuxrc.vnc || Linuxrc.usessh ||
          Linuxrc.text)
    end



    # Restore the the data from sysconfig.
    #
    # @return  true	- Data could be restored
    #		false	- Restore not successful
    #
    # @see #Save()
    def Restore
      ret = false
      @restore_called = true


      if !Stage.initial || Mode.live_installation
        # Read YaST2 keyboard var.
        #
        @current_kbd = Misc.SysconfigRead(
          path(".sysconfig.keyboard.YAST_KEYBOARD"),
          ""
        )
        pos = Builtins.find(@current_kbd, ",")
        if pos != nil && Ops.greater_than(pos, 0)
          @kb_model = Builtins.substring(@current_kbd, Ops.add(pos, 1))
          @current_kbd = Builtins.substring(@current_kbd, 0, pos)
        end

        Builtins.y2milestone("current_kbd %1 model %2", @current_kbd, @kb_model)
        if @current_kbd == ""
          Builtins.y2milestone("Restoring data failed, returning defaults")
          @current_kbd = "english-us"
          @kb_model = "pc104"
          ret = false
        else
          if !Mode.config
            # Restore module data.
            #
            SetKeyboard(@current_kbd)
            Builtins.y2milestone(
              "Restored data (sysconfig) for keyboard: <%1>",
              @current_kbd
            )
          else
            # for cloning, to be shown in Summary
            @name = GetKeyboardName(@current_kbd)
          end
          ret = true
        end
      else
        ret = true
      end
      ret
    end # Restore()

    # Keyboard()
    #
    # The module constructor.
    # Sets the proprietary module data defined globally for public access.
    # This is done only once (and automatically) when the module is loaded for the first time.
    #
    # @see #Probe()
    def Keyboard
      return if Mode.config

      # We have these possible sources of information:
      #
      # probed data:	- installation initial mode --> probing
      # sysconfig:	- installation continue mode or normal mode
      #
      Builtins.y2milestone("initial :%1, update:%2", Stage.initial, Mode.update)

      success = false

      # If not in initial mode try to restore from sysconfig.
      if !Stage.initial || Mode.live_installation
        success = Restore()
      else
#        GetKbdSysconfig()
      end

      # In initial mode or if restoring failed do probe.
      if !success
        # On module entry probe the hardware and set all those data
        # needed for public access.
        Probe()
      end

      nil
    end # Keyboard()

    # Just store inital values - read was done in constructor
    def Read
      @keyboard_on_entry = @current_kbd
      Builtins.y2debug("keyboard_on_entry: %1", @keyboard_on_entry)
      true
    end

    # was anything modified?
    def Modified
      @current_kbd != @keyboard_on_entry
    end


    # Save the current data into a file to be read after a reboot.
    #
    def Save
      if Mode.update
        log.info "skipping country changes in update"
        return
      end

      # Write some sysconfig variables.
      #
      SCR.Write(
        path(".sysconfig.keyboard.YAST_KEYBOARD"),
        "#{@current_kbd},#{@kb_model}"
      )
      SCR.Write(
        path(".sysconfig.keyboard.YAST_KEYBOARD.comment"),
        "\n" +
          "# The YaST-internal identifier of the attached keyboard.\n" +
          "#\n"
      )

      SCR.Write(path(".sysconfig.keyboard.KBD_RATE"), @kbd_rate)
      SCR.Write(path(".sysconfig.keyboard.KBD_DELAY"), @kbd_delay)
      SCR.Write(path(".sysconfig.keyboard.KBD_NUMLOCK"), @kbd_numlock)
      SCR.Write(
        path(".sysconfig.keyboard.KBD_DISABLE_CAPS_LOCK"),
        @kbd_disable_capslock
      )
      SCR.Write(path(".sysconfig.keyboard"), nil) # flush

      chomped_keymap = @keymap.chomp(".map.gz")

      if Stage.initial
        # do use --root option, running in chroot does not work (bsc#1074481)
        cmd = "/usr/bin/systemd-firstboot --root #{Installation.destdir.shellescape} --keymap #{chomped_keymap.shellescape}"
        result = WFM.Execute(path(".local.bash_output"), cmd)
      else
        # this sets both the console and the X11 keyboard (see "man localectl")
        cmd = "/usr/bin/localectl set-keymap #{chomped_keymap.shellescape}"
        result = SCR.Execute(path(".target.bash_output"), cmd)
      end

      log.info "Making keyboard settings persistent: command #{cmd} end with #{result.inspect}"

      if result["exit"] != 0
        log.error "Keyboard configuration not written. Failed to execute '#{cmd}'"
        log.error "output: #{result.inspect}"
        # TRANSLATORS: the "%s" is replaced by the executed command
        Report.Error(_("Could not save the keyboard setting, the command\n%s\nfailed.") % cmd)
      end

      # As a preliminary step mark all keyboards except the one to be configured
      # as configured = no and needed = no. Afterwards this one keyboard will be
      # marked as configured = yes and needed = yes. This has to be done  to
      # prevent any problems that may occur if the user plugs in and out different
      # keyboards or if a keyboard is selected from the database despite the fact
      # that a keyboard has been probed. Otherwise the config popup may nag the user
      # again and again.
      #
      # In order to get a list of *ALL* keyboards that have ever been conected to
      # the system we must do a *manual* probing (accessing the libhd database).
      # Doing only a "normal" probing would deliver only the *currently* attached
      # keyboards which in turn would not allow to "unmark" all keyboards that may
      # have been removed.
      #
      # Manual probing
      @keyboardprobelist = Convert.to_list(
        SCR.Read(path(".probe.keyboard.manual"))
      )

      log.info "No probed keyboards. Not unconfiguring any keyboards" if @keyboardprobelist.empty?


      nil
    end # Save()

    # Checks if initrd must be regenerated
    #
    # According to bnc#888804, initrd must be regenerated in order for any
    # configuration change to survive to reboots. That means a regeneration is
    # needed unless we are installing or updating (in those situations it will
    # be a initrd generation at some point in the future for sure).
    def needs_new_initrd?
      Mode.normal
    end

    # Name()
    # Just return the keyboard name, without setting anything.
    # @return [String] user readable description.

    def Name
      @name
    end

    # Set the console keyboard to the given keyboard language.
    #
    # @param	Keyboard language e.g.  "english-us"
    #
    def SetConsole(keyboard)
      if Mode.test
        Builtins.y2milestone("Test mode - NOT setting keyboard")
      elsif Arch.board_iseries || Arch.s390 # workaround for bug #39025
        Builtins.y2milestone("not calling loadkeys on iseries")
      else
        SetKeyboard(keyboard)

        Builtins.y2milestone("Setting console keyboard to: <%1>", @current_kbd)
        Builtins.y2milestone("loadkeys command: <%1>", @ckb_cmd)
        SCR.Execute(path(".target.bash"), @ckb_cmd)

        # It could be that for seriell tty's the keyboard cannot be set. So it will
        # be done separately in order to ensure that setting console keyboard
        # will be done successfully in the previous call.
        Builtins.y2milestone("Setting seriell console keyboard to: <%1>", @current_kbd)
        Builtins.y2milestone("loadkeys command: <%1>", @skb_cmd)
        SCR.Execute(path(".target.bash"), @skb_cmd)

        UI.SetKeyboard
      end
    end # SetConsole()


    # Set the X11 keyboard to the given keyboard language.
    #
    # @param	Keyboard language e.g.  "english-us"
    #
    # @return  The xkbset command that has been executed to do it.
    #		(also stored in Keyboard::xkb_cmd)
    def SetX11(keyboard)
      if Mode.test
        log.info "Test mode - would have called:\n #{@xkb_cmd}"
      else
        # Actually do it only if we are in graphical mode.
        #
        if textmode?
          log.info "Not setting X keyboard due to text mode"
        # check if we are running over ssh: bnc#539218,c4
        elsif x11_over_ssh?
          # TODO: the check above could not be enough in some cases
          # An external X server can be specified via display_ip boot parameter
          # (see https://en.opensuse.org/SDB:Linuxrc#p_displayip).
          # I that case, the configuration should probably also be skipped
          log.info "Not setting X keyboard: running over ssh"
        elsif !@xkb_cmd.empty?
          SetKeyboard(keyboard)
          execute_xkb_cmd
          # bnc#371756: enable autorepeat if needed
          enable_autorepeat
        end
      end
      @xkb_cmd
    end # SetX11()


    # Set()
    #
    # Set the keyboard to the given keyboard language.
    #
    # @param   Keyboard language e.g.  "english-us"
    #
    # @return  [void]
    #
    # @see     SetX11(), SetConsole()

    def Set(keyboard)
      Builtins.y2milestone("set to %1", keyboard)
      if Mode.config
        @name = GetKeyboardName(@current_kbd)
        return
      end

      # Store keyboard just set.
      #
      @current_kbd = keyboard

      # On first assignment store default keyboard.
      #
      @default_kbd = @current_kbd if @default_kbd == "" # not yet assigned

      SetConsole(keyboard)
      SetX11(keyboard)
      if Stage.initial && !Mode.live_installation
        yinf = {}
        yinf_ref = arg_ref(yinf)
        AsciiFile.SetDelimiter(yinf_ref, " ")
        yinf = yinf_ref.value
        yinf_ref = arg_ref(yinf)
        AsciiFile.ReadFile(yinf_ref, "/etc/yast.inf")
        yinf = yinf_ref.value
        lines = AsciiFile.FindLineField(yinf, 0, "Keytable:")
        if Ops.greater_than(Builtins.size(lines), 0)
          yinf_ref = arg_ref(yinf)
          AsciiFile.ChangeLineField(
            yinf_ref,
            Ops.get_integer(lines, 0, -1),
            1,
            @keymap
          )
          yinf = yinf_ref.value
        else
          yinf_ref = arg_ref(yinf)
          AsciiFile.AppendLine(yinf_ref, ["Keytable:", @keymap])
          yinf = yinf_ref.value
        end
        yinf_ref = arg_ref(yinf)
        AsciiFile.RewriteFile(yinf_ref, "/etc/yast.inf")
        yinf = yinf_ref.value
      end

      nil
    end


    # MakeProposal()
    #
    # Return proposal string and set system keyboard.
    #
    # @param [Boolean] force_reset
    #		boolean language_changed
    #
    # @return	[String]	user readable description.
    #		If force_reset is true reset the module to the keyboard
    #		stored in default_kbd.

    def MakeProposal(force_reset, language_changed)
      Builtins.y2milestone("force_reset: %1", force_reset)
      Builtins.y2milestone("language_changed: %1", language_changed)

      if force_reset
        # If user wants to reset do it if a default is available.
        if @default_kbd != ""
          Set(@default_kbd) # reset
        end

        # Reset user_decision flag.
        @user_decision = false
        @restore_called = false # no reset
      else
        # Only follow the language if the user has never actively chosen
        # a keyboard. The indicator for this is user_decision which is
        # set from outside the module.
        if @user_decision || Mode.update && !Stage.initial || Mode.auto ||
            Mode.live_installation ||
            ProductFeatures.GetStringFeature("globals", "keyboard") != ""
          if language_changed
            Builtins.y2milestone(
              "User has chosen a keyboard; not following language - only retranslation."
            )

            Set(@current_kbd)
          end
        else
          # User has not yet chosen a keyboard ==> follow language.
          local_kbd = GetKeyboardForLanguage(Language.language, "english-us")
          if local_kbd != ""
            Set(local_kbd)
          elsif language_changed
            Builtins.y2error("Can't follow language - only retranslation")
            Set(@current_kbd)
          end
        end
      end
      @name
    end # MakeProposal()

    # Selection()
    #
    # Get the map of translated keyboard names.
    #
    # @return	[Hash] of $[ keyboard_code : keyboard_name, ...] for all known
    #		keyboards. 'keyboard_code' is used internally in Set and Get
    #		functions. 'keyboard_name' is a user-readable string.
    #
    def Selection
      # Get the reduced keyboard DB.
      #
      keyboards = get_reduced_keyboard_db
      translate = ""
      trans_str = ""

      Builtins.mapmap(keyboards) do |keyboard_code, keyboard_value|
        translate = Ops.get_string(keyboard_value, 0, "")
        trans_str = Builtins.eval(translate)
        { keyboard_code => trans_str }
      end
    end

    # Return item list of keyboard items, sorted according to current language
    # @return [Array<Term>] Item(Id(...), String name, Boolean selected)
    def GetKeyboardItems
      ret = Builtins.maplist(Selection()) do |code, name|
        Item(Id(code), name, @current_kbd == code)
      end
      Builtins.sort(ret) do |a, b|
        # bnc#385172: must use < instead of <=, the following means:
        # strcoll(x) <= strcoll(y) && strcoll(x) != strcoll(y)
        lsorted = Builtins.lsort(
          [Ops.get_string(a, 1, ""), Ops.get_string(b, 1, "")]
        )
        lsorted_r = Builtins.lsort(
          [Ops.get_string(b, 1, ""), Ops.get_string(a, 1, "")]
        )
        Ops.get_string(lsorted, 0, "") == Ops.get_string(a, 1, "") &&
          lsorted == lsorted_r
      end
    end


    # set the keayboard layout according to given language
    def SetKeyboardForLanguage(lang)
      lkbd = GetKeyboardForLanguage(lang, "english-us")
      Builtins.y2milestone("language %1 proposed keyboard %2", lang, lkbd)
      Set(lkbd) if lkbd != ""

      nil
    end

    def SetKeyboardForLang(lang)
      SetKeyboardForLanguage(lang)
    end

    def SetKeyboardDefault
      Builtins.y2milestone("SetKeyboardDefault to %1", @current_kbd)
      @default_kbd = @current_kbd

      nil
    end

    # AutoYaST interface function: Get the Keyboard configuration from a map.
    #
    # @param settings [Hash] imported map with the content of either the
    #       'keyboard' or the 'language' section
    # @param syntax [:keyboard, :language] format of settings: if :language, the
    #       data for Language.Import
    # @return success
    def Import(settings, syntax = :keyboard)
      settings = deep_copy(settings)
      # Read was not called -> do the init
      Read() 

      keyboard = @current_kbd
      expert_values = {}

      case syntax
      when :keyboard
        keyboard = settings["keymap"] if settings["keymap"]
        expert_values = settings["keyboard_values"] if settings["keyboard_values"]
      when :language
        keyboard = GetKeyboardForLanguage(settings["language"], keyboard)
      end
      Set(keyboard)
      true
    end

    # AutoYaST interface function: Return the Keyboard configuration as a map.
    # @return [Hash] with the settings
    def Export

      ret = { "keymap" => @current_kbd }
      Ops.set(ret, "keyboard_values", diff_values) if diff_values != {}
      deep_copy(ret)
    end

    # AutoYaST interface function: Return the summary of Keyboard configuration as a map.
    # @return summary string (html)
    def Summary
      Yast.import "HTML"

      ret = [
        # summary label
        Builtins.sformat(_("Current Keyboard Layout: %1"), @name)
      ]
      HTML.List(ret)
    end

    publish :variable => :keymap, :type => "string"
    publish :variable => :XkbOptions, :type => "string"
    publish :variable => :current_kbd, :type => "string"
    publish :variable => :keyboard_on_entry, :type => "string"
    publish :variable => :default_kbd, :type => "string"
    publish :variable => :user_decision, :type => "boolean"
    publish :function => :Set, :type => "void (string)"
    publish :function => :GetKeyboardForLanguage, :type => "string (string, string)"
    publish :function => :SetKeyboard, :type => "boolean (string)"
    publish :function => :Restore, :type => "boolean ()"
    publish :function => :Keyboard, :type => "void ()"
    publish :function => :Read, :type => "boolean ()"
    publish :function => :Modified, :type => "boolean ()"
    publish :function => :Save, :type => "void ()"
    publish :function => :Name, :type => "string ()"
    publish :function => :SetConsole, :type => "void (string)"
    publish :function => :SetX11, :type => "string (string)"
    publish :function => :MakeProposal, :type => "string (boolean, boolean)"
    publish :function => :Selection, :type => "map <string, string> ()"
    publish :function => :GetKeyboardItems, :type => "list <term> ()"
    publish :function => :SetKeyboardForLanguage, :type => "void (string)"
    publish :function => :SetKeyboardForLang, :type => "void (string)"
    publish :function => :SetKeyboardDefault, :type => "void ()"
    publish :function => :Import, :type => "boolean (map, ...)"
    publish :function => :Export, :type => "map ()"
    publish :function => :Summary, :type => "string ()"

  private

    # Enforces the generation of initrd
    def regenerate_initrd
      log.info "Regenerating initrd to make the change persistent"
      # The three steps are necessary with the current Initrd API
      Initrd.Read
      Initrd.Update
      Initrd.Write
    end


    # Checks if the graphical environment is being executed remotely using
    # "ssh -X"
    def x11_over_ssh?
      display = ENV["DISPLAY"] || ""
      display.split(":")[1].to_i >= 10
    end

    # Checks if it's running in text mode (no X11)
    def textmode?
      if !Stage.initial || Mode.live_installation
        UI.TextMode
      else
        Linuxrc.text
      end
    end

    # Executes the command to set the keyboard in X11, reporting
    # any error to the user
    def execute_xkb_cmd
      log.info "Setting X11 keyboard to: <#{@current_kbd}>"
      log.info "Setting X11 keyboard: #{@xkb_cmd}"
      if SCR.Execute(path(".target.bash"), @xkb_cmd) != 0
        log.error "Failed to execute the command"
        Report::Error(_("Failed to set X11 keyboard to '%s'") % @current_kbd)
      end
    end

    # Enables autorepeat if needed
    def enable_autorepeat
      return nil unless Stage.initial && !Mode.live_installation && !xen_running
      cmd = "/usr/bin/xset r on"
      log.info "calling xset to fix autorepeat problem: #{cmd}"
      SCR.Execute(path(".target.bash"), cmd)
    end

  end

  Keyboard = KeyboardClass.new
  Keyboard.main
end

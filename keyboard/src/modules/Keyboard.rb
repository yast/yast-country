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
require "y2keyboard/strategies/systemd_strategy"
require "y2keyboard/keyboards"

module Yast
  class KeyboardClass < Module
    include Yast::Logger

    def main
      textdomain "country"

      Yast.import "Language"
      Yast.import "Mode"
      Yast.import "ProductFeatures"
      Yast.import "Stage"
      Yast.import "Report"

      # general kb strategy which is used for temporary changes only.
      @kb_strategy = Y2Keyboard::Strategies::KbStrategy.new

      # systemd strategy used in the installed system
      @systemd_strategy = Y2Keyboard::Strategies::SystemdStrategy.new

      # The keyboard currently set. E.g. "english-us"
      #
      @curr_kbd = ""

      # keyboard set on start. E.g. "english-us"
      #
      @keyboard_on_entry = ""

      # The default keyboard if set.  E.g. "english-us"
      #
      @default_kbd = ""

      # Flag indicating if the user has chosen a keyboard.
      # To be set from outside.
      #
      @user_decision = false

      # modify flag
      @modified = false
    end

    # Get the keyboard language for the given system language.
    #
    # @param [String] System language code, e.g. "en_US".
    # @param [String] Default keyboard language to be returned if nothing found.
    #                 E.g. "english-us"
    #
    # @return  The keyboard language for this language, e.g. "english-us"
    #	       or the default value if nothing found.
    #
    def GetKeyboardForLanguage(sys_language, default_keyboard)
      ret = Keyboards.suggested_keyboard(sys_language) ||
        Language.GetLang2KeyboardMap(true)[sys_language] || # The language module has also suggestions
        default_keyboard
      log.info("Suggest keyboard #{ret} for language #{sys_language}")
      ret
    end

    # Read installed keyboard settings.
    def Read
      if !Stage.initial || Mode.live_installation
        curr_code = ConvertLegacyKeymapCode(@systemd_strategy.current_layout)
        @curr_kbd = Keyboards.alias(curr_code)
        if @curr_kbd.nil?
          log.warn "Unsupported keymap #{@systemd_strategy.current_layout}."
          @curr_kbd = ""
        end
        @keyboard_on_entry = @curr_kbd
      end

      log.info("keyboard_on_entry: #{@keyboard_on_entry}")
      true
    end

    # was anything modified?
    #
    # @return [Boolean] true if modified
    def Modified
      @curr_kbd != @keyboard_on_entry || @modified
    end

    # Set to modified
    def SetModified
      @modified = true
    end

    # Convert a legacy keymap code to the corresponding new one. Leave it
    # unchanged if it's not a known legacy keymap.
    #
    # @param [String] kb_code keymap code to check and/or change
    #
    # @return [String] changed keymap code
    #
    def ConvertLegacyKeymapCode(kb_code)
      return kb_code unless Keyboards.legacy_code?(kb_code)

      new_kb_code = Keyboards.legacy_replacement(kb_code)
      log.info("Changing obsolete legacy keymap code '#{kb_code}' to '#{new_kb_code}'")
      Keyboard.SetModified
      new_kb_code
    end

    # Set current data into the installed system.
    def Save
      if Mode.update
        log.info "skipping country changes in update"
        return
      end
      key_code = Keyboards.code(@curr_kbd)
      log.info("Saving keyboard #{@curr_kbd}/#{key_code} to system")
      @systemd_strategy.apply_layout(key_code)
      @keyboard_on_entry = @curr_kbd
      nil
    end

    # Set the keyboard to the given keyboard language.
    #
    # @param   [String] Keyboard language e.g.  "english-us"
    # @return  [nil]
    def Set(keyboard)
      log.info "set to #{keyboard}"

      # Store keyboard just set.
      #
      @curr_kbd = keyboard

      # On first assignment store default keyboard.
      #
      @default_kbd = @curr_kbd if @default_kbd == "" # not yet assigned

      if !Mode.config # not in AY configuration module
        # Set keyboard in the running system
        @kb_strategy.set_layout(Keyboards.code(keyboard))
      end

      nil
    end

    # Return proposal string and set system keyboard.
    #
    # @param [Boolean] force_reset
    # @param [Boolean] language_changed
    #
    # @return	[String]	user readable description.
    #		If force_reset is true reset the module to the keyboard
    #		stored in default_kbd.
    def MakeProposal(force_reset, language_changed)
      log.info("force_reset: #{force_reset}")
      log.info("language_changed: #{language_changed}")

      if force_reset
        # If user wants to reset do it if a default is available.
        if @default_kbd != ""
          Set(@default_kbd) # reset
        end

        # Reset user_decision flag.
        @user_decision = false
      elsif @user_decision || (Mode.update && !Stage.initial) ||
          Mode.live_installation ||
          (Mode.auto && !@curr_kbd.empty?) || # AY has already set keyboard
          ProductFeatures.GetStringFeature("globals", "keyboard") != ""
        # Only follow the language if the user has never actively chosen
        # a keyboard. The indicator for this is user_decision which is
        # set from outside the module.
        if language_changed
          log.info(
            "User has chosen a keyboard; not following language."
          )
        end
      else
        # User has not yet chosen a keyboard ==> follow language.
        local_kbd = GetKeyboardForLanguage(Language.language, "english-us")
        if local_kbd != ""
          Set(local_kbd)
        elsif language_changed
          log.error("Can't follow language - only retranslation")
          Set(@curr_kbd)
        end
      end
      Keyboards.description(@curr_kbd)
    end

    # Get the map of translated keyboard names.
    #
    # @return	[Hash] of $[ keyboard_alias : keyboard_description, ...] for all known
    #		keyboards. 'keyboard_alias' is used internally in Set and Get
    #		functions. 'keyboard_description' is a user-readable string.
    #           e.g. {"arabic"=>"Arabic", "belgian"=>"Belgian",....}
    #
    def Selection
      lang = Keyboards.all_keyboards.map { |k| { k["alias"] => k["description"] } }
      Hash[*lang.collect(&:to_a).flatten]
    end

    # Returns all defined codes and the regarding aliases.
    #
    # @return	[Hash] of $[ keyboard_code : keyboard_alias, ...] for all known
    #		keyboards. 'keyboard_code' is the system key map
    #		functions. 'keyboard_alias' is used internally in Set and Get
    #           e.g. {"jp106"=>"japanese", "us"=>"english-us",....}
    def Codes
      lang = Keyboards.all_keyboards.map { |k| { k["code"] => k["alias"] } }
      Hash[*lang.collect(&:to_a).flatten]
    end

    # Return item list of keyboard items, sorted according to current language
    # @return [Array<Term>] Item(Id(...), String name, Boolean selected)
    def GetKeyboardItems
      ret = Builtins.maplist(Selection()) do |code, name|
        Item(Id(code), name, @curr_kbd == code)
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

    # Set the keyboard layout according to given language
    # @param  [String] language e.g. "en"
    def SetKeyboardForLanguage(lang)
      lang_kbd = GetKeyboardForLanguage(lang, "english-us")
      log.info("language #{lang} proposed keyboard #{lang_kbd}")
      Set(lang_kbd) if lang_kbd != ""
    end

    # Set the current keyboard as default
    def SetKeyboardDefault
      log.info("SetKeyboardDefault to #{@curr_kbd}")
      @default_kbd = @curr_kbd
    end

    # AutoYaST interface function: Get the Keyboard configuration from a map.
    #
    # @param [Hash] settings; imported map with the content of either the
    #       'keyboard' or the 'language' section
    # @param [:keyboard, :language] syntax ; format of settings: if :language, the
    #       data for Language.Import
    # @return success
    def Import(settings, syntax = :keyboard)
      settings = deep_copy(settings)
      # Read was not called -> do the init
      Read() unless Mode.config # not in AY configuration module

      keyboard = @curr_kbd

      case syntax
      when :keyboard
        keyboard = settings["keymap"] if settings["keymap"]
      when :language
        keyboard = GetKeyboardForLanguage(settings["language"], keyboard)
      end

      keyboard = ConvertLegacyKeymapCode(keyboard)

      # Checking if the keymap exists. Either it is the real keymap name
      # or an alias.
      if !Keyboards.code(keyboard)
        # Checking if it a real keymap name
        checked_keyboard = keyboard
        keyboard = Keyboards.alias(checked_keyboard)
        if !keyboard
          # TRANSLATORS: "%s" is the keymap name
          Report.Warning(_("Cannot find keymap: %s. Taking default one.") % checked_keyboard)
          return false
        end
      end

      # Set it with the keyboard alias name
      Set(keyboard)
      true
    end

    # AutoYaST interface function: Return the Keyboard configuration as a map.
    # @return [Hash] with the settings
    def Export
      ret = {}

      if @curr_kbd == Keyboard.GetKeyboardForLanguage(Language.language,
        "english-us")
        log.info("keymap #{@curr_kbd} is the default of language " \
                 "#{Language.language} --> no export")
      else
        ret["keymap"] = @curr_kbd
      end
      deep_copy(ret)
    end

    # AutoYaST interface function: Return the summary of Keyboard configuration as a map.
    # @return summary string (html)
    def Summary
      Yast.import "HTML"

      ret = [
        # summary label
        format(_("Current Keyboard Layout: %s"), Keyboards.description(@curr_kbd))
      ]
      HTML.List(ret)
    end

    # Returning current keyboard
    # @return [String] keyboard name e.g. "english-us"
    def current_kbd
      self.Read if @curr_kbd.empty? && !Mode.config
      @curr_kbd
    end

    publish variable: :keyboard_on_entry, type: "string"
    publish variable: :default_kbd, type: "string"
    publish variable: :user_decision, type: "boolean"
    publish function: :current_kbd, type: "string ()"
    publish function: :Set, type: "void (string)"
    publish function: :GetKeyboardForLanguage, type: "string (string, string)"
    publish function: :Read, type: "boolean ()"
    publish function: :Modified, type: "boolean ()"
    publish function: :SetModified, type: "void (boolean)"
    publish function: :Save, type: "void ()"
    publish function: :MakeProposal, type: "string (boolean, boolean)"
    publish function: :Selection, type: "map <string, string> ()"
    publish function: :codes, type: "map <string,string> ()"
    publish function: :GetKeyboardItems, type: "list <term> ()"
    publish function: :SetKeyboardForLanguage, type: "void (string)"
    publish function: :SetKeyboardDefault, type: "void ()"
    publish function: :Import, type: "boolean (map, ...)"
    publish function: :Export, type: "map ()"
    publish function: :Summary, type: "string ()"
  end

  Keyboard = KeyboardClass.new
  Keyboard.main
end

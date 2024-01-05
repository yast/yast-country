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
# Module:		yast2-country
#
# Authors:		Klaus Kaempf (kkaempf@suse.de)
#			Jiri Suchomel (jsuchome@suse.cz)
#
# Purpose:		client for language configuration in running system
#
# $Id$
module Yast
  class LanguageClient < Client
    def main
      Yast.import "UI"

      textdomain "country"

      Yast.import "CommandLine"
      Yast.import "Console"
      Yast.import "Keyboard"
      Yast.import "Language"
      Yast.import "Mode"
      Yast.import "Popup"
      Yast.import "Progress"
      Yast.import "Service"
      Yast.import "Wizard"

      # if packages should be installed after language change
      @no_packages = false

      # -- the command line description map --------------------------------------
      @cmdline = {
        "id"         => "language",
        # translators: command line help text for language module
        "help"       => _(
          "Language configuration"
        ),
        "guihandler" => fun_ref(method(:LanguageSequence), "any ()"),
        "initialize" => fun_ref(method(:LanguageRead), "boolean ()"),
        "finish"     => fun_ref(method(:LanguageWrite), "boolean ()"),
        "actions"    => {
          "summary" => {
            "handler"  => fun_ref(
              method(:LanguageSummaryHandler),
              "boolean (map)"
            ),
            # command line help text for 'summary' action
            "help"     => _(
              "Language configuration summary"
            ),
            "readonly" => true
          },
          "set"     => {
            "handler" => fun_ref(method(:LanguageSetHandler), "boolean (map)"),
            # command line help text for 'set' action
            "help"    => _(
              "Set new values for language"
            )
          },
          "list"    => {
            "handler"  => fun_ref(method(:LanguageListHandler), "boolean (map)"),
            # command line help text for 'list' action
            "help"     => _(
              "List all available languages."
            ),
            "readonly" => true
          }
        },
        "options"    => {
          "lang"        => {
            # command line help text for 'set lang' option
            "help" => _(
              "New language value"
            ),
            "type" => "string"
          },
          "languages"   => {
            # command line help text for 'set languages' option
            "help" => _(
              "List of secondary languages (separated by commas)"
            ),
            "type" => "string"
          },
          "no_packages" => {
            # command line help text for 'set no_packages' option
            "help" => _(
              "Do not install language specific packages"
            )
          }
        },
        "mappings"   => {
          "summary" => [],
          "set"     => ["lang", "languages", "no_packages"],
          "list"    => []
        }
      }

      CommandLine.Run(@cmdline)
    end

    # read language settings
    def LanguageRead
      Language.Read(false)
    end

    # write language settings
    def LanguageWrite
      Builtins.y2milestone("Language changed --> saving")

      steps = 3

      # progress title
      Progress.New(
        _("Saving Language Configuration"),
        " ",
        steps,
        [
          # progress stage
          _("Save language and console settings"),
          # progress stage
          _("Install and uninstall affected packages"),
          # progress stage
          _("Update translations in boot loader menu")
        ],
        [
          # progress step
          _("Saving language and console settings..."),
          # progress step
          _("Installing and uninstalling affected packages..."),
          # progress step
          _("Updating translations in boot loader menu...")
        ],
        ""
      )

      Progress.NextStage

      Language.Save
      Console.Save

      Progress.NextStage

      enough_space = true
      solved = true
      if Language.PackagesModified && !@no_packages
        if Mode.commandline
          # if not commandline, packages were already initialized in
          # select_language
          solved = Language.PackagesInit(
            Builtins.splitstring(Language.languages, ",")
          )
          enough_space = Language.EnoughSpace

          Builtins.y2milestone(
            "Packages solved: %1, enough space; %2",
            solved,
            enough_space
          )
        end
        Language.PackagesCommit if enough_space && solved
      end

      Progress.NextStage

      # switch the UI to new language (after packages installation), so
      # the texts in GfxMenu can be translated (bnc#446982)
      Language.WfmSetLanguage

      if Keyboard.Modified
        # restart kbd now (after console settings is written) bnc#429515
        Service.Restart("kbd")
      end

      true
    end

    # the language configuration sequence
    def LanguageSequence
      LanguageRead()

      Keyboard.Read

      Console.Init

      Wizard.CreateDialog

      # set the language according to Language.ycp initialization
      Language.WfmSetLanguage
      Wizard.OpenOKDialog

      # Params are:				`back `next  set_default
      args = {}
      Ops.set(args, "enable_back", true)
      Ops.set(args, "enable_next", true)

      result = WFM.CallFunction("select_language", [args])

      Wizard.CloseDialog

      Builtins.y2debug("result '%1'", result)

      if [:cancel, :back].include?(result)
        # Back to original values...
        Builtins.y2milestone(
          "canceled -> restoring: %1",
          Language.language_on_entry
        )
        Language.Set(Language.language_on_entry)
      elsif Language.Modified
        Wizard.RestoreHelp(
            _("<p><b>Saving Configuration</b><br>Please wait...</p>")
          )
        Console.SelectFont(Language.language)
        LanguageWrite()
      # help for write dialog
      else
        Builtins.y2milestone("Language not changed --> doing nothing")
      end
      UI.CloseDialog
      deep_copy(result)
    end

    # Handler for language summary
    def LanguageSummaryHandler(options)
      options = deep_copy(options)
      selection = Language.Selection
      # summary label
      CommandLine.Print(
        Builtins.sformat(
          _("Current Language: %1 (%2)"),
          Language.language,
          Ops.get_string(selection, [Language.language, 1], "")
        )
      )

      languages = Language.languages
      if languages != ""
        langs = Builtins.filter(Builtins.splitstring(languages, ",")) do |lang_code|
          lang_code != Language.language
        end
        if Ops.greater_than(Builtins.size(langs), 0)
          CommandLine.Print(
            Builtins.sformat(
              _("Additional Languages: %1"),
              Builtins.mergestring(langs, ",")
            )
          )
        end
      end
      true
    end

    # Handler for listing available languages
    def LanguageListHandler(options)
      options = deep_copy(options)
      Builtins.foreach(Language.Selection) do |lang_code, lang_info|
        CommandLine.Print(
          Builtins.sformat(
            "%1 (%2)",
            lang_code,
            Ops.get_string(lang_info, 1, "")
          )
        )
      end
      true
    end

    # Handler for changing language settings
    def LanguageSetHandler(options)
      options = deep_copy(options)
      language = Ops.get_string(options, "lang", Language.language)
      languages = Ops.get_string(options, "languages", "")

      if !Builtins.haskey(Language.Selection, language)
        # error message (%1 is given layout); do not translate 'list'
        CommandLine.Print(
          Builtins.sformat(
            _(
              "%1 is not a valid language. Use the list command to see possible values."
            ),
            language
          )
        )
        return false
      end
      llanguages = Builtins.splitstring(languages, ",")
      llanguages = Builtins.add(llanguages, language) if !Builtins.contains(llanguages, language)

      Language.languages = Builtins.mergestring(llanguages, ",")

      if language != Language.language
        Language.Set(language)
        Console.SelectFont(language)
      end
      @no_packages = Builtins.haskey(options, "no_packages")

      Language.Modified
    end
  end
end

Yast::LanguageClient.new.main

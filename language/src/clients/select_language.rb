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
#	select_language.ycp
#
# Module:
#	yast2-country
#
# Authors:
#	Klaus   Kämpf <kkaempf@suse.de>
#	Michael Hager <mike@suse.de>
#	Stefan  Hundhammer <sh@suse.de>
#	Thomas Roelz <tom@suse.de>
#	Jiri Suchomel <jsuchome@suse.cz>
#
# Summary:
#	This client shows main dialog for choosing the language.
#
# $Id$
#
module Yast
  class SelectLanguageClient < Client
    def main
      Yast.import "Pkg"
      Yast.import "UI"
      textdomain "country"

      Yast.import "Console"
      Yast.import "GetInstArgs"
      Yast.import "Keyboard"
      Yast.import "Label"
      Yast.import "Language"
      Yast.import "Mode"
      Yast.import "PackageSlideShow"
      Yast.import "Popup"
      Yast.import "ProductFeatures"
      Yast.import "Report"
      Yast.import "SlideShow"
      Yast.import "Stage"
      Yast.import "Timezone"
      Yast.import "Wizard"
      Yast.import "PackagesUI"

      @language = Language.language

      # ------------------------------------- main part of the client -----------

      @argmap = GetInstArgs.argmap

      # Check if the current call should be treated as the first run (3rd param).
      # In this case if the user exits with next the the current setting
      # will be made the default that is restored with "Reset to defaults".
      #
      @set_default = Ops.get_string(@argmap, "first_run", "no") == "yes"
      Builtins.y2milestone("set_default: %1", @set_default)

      @preselected = Language.preselected

      if @preselected != "en_US" && @set_default
        if ProductFeatures.GetBooleanFeature("globals", "skip_language_dialog")
          Builtins.y2milestone(
            "Skipping language dialog, Language changed to %1",
            @preselected
          )
          Language.CheckLanguagesSupport(@preselected)
          Language.selection_skipped = true
          return :auto
        end
      end


      # when the possibility for selecting more languages should be shown
      # (this includes differet UI layout)
      @more_languages = true

      @languages = Builtins.splitstring(Language.languages, ",")

      # filter the primary language from the list of secondary ones:
      @languages = Builtins.filter(@languages) { |l| l != @language }


      # Build the contents of the dialog.

      # build up language selection box
      # with the default selection according to Language::language

      # set up selection list with default item

      @show_expert = true

      # ----------------------------------------------------------------------
      # Build dialog
      # ----------------------------------------------------------------------
      # heading text
      @heading_text = _("Languages")

      if @set_default && !Mode.repair
        # heading text
        @heading_text = _("Language")
      end
      if Mode.repair
        # heading text
        @heading_text = _("Welcome to System Repair")
      end

      if @set_default
        @show_expert = false
        @more_languages = false
      end

      @languagesel = Empty()
      if Stage.initial # this is actually not reached now...
        @languagesel = SelectionBox(
          Id(:language),
          Opt(:notify),
          "",
          Language.GetLanguageItems(:first_screen)
        )
      end

      if Stage.firstboot
        @languagesel = SelectionBox(
          Id(:language),
          Opt(:notify),
          "",
          Language.GetLanguageItems(:primary)
        )
      end

      @contents = VBox(
        VSpacing(),
        HBox(
          HWeight(1, HSpacing()),
          HWeight(3, @languagesel),
          HWeight(1, HSpacing())
        ),
        VSpacing()
      )

      @expert = HStretch()
      if @show_expert
        @expert = VBox(
          Label(""),
          # button label
          PushButton(Id(:expert), _("&Details"))
        )
      end

      @primary_items = []
      @secondary_items = []

      # if checkboxes for adapting keyboard and timezone should be shown
      @adapt_term = @more_languages && !Mode.config
      if @more_languages
        @languages_term = MultiSelectionBox(
          Id(:languages),
          # multiselection box label
          _("&Secondary Languages")
        )
        @primary_items = Language.GetLanguageItems(:primary)
        @secondary_items = Language.GetLanguageItems(:secondary)

        @primary_term = HBox(
          Left(
            ComboBox(
              Id(:language),
              Opt(:notify),
              # combo box label
              _("Primary &Language"),
              @primary_items
            )
          ),
          Right(@expert)
        )

        if @adapt_term
          # frame label
          @primary_term = Frame(
            _("Primary Language Settings"),
            HBox(
              HSpacing(0.5),
              VBox(
                @primary_term,
                VSpacing(0.5),
                ReplacePoint(Id(:rpadapt), VBox()),
                VSpacing(0.5)
              ),
              HSpacing(0.5)
            )
          )
        end

        @contents = VBox(
          VSpacing(),
          HBox(
            HSpacing(2),
            VBox(
              @primary_term,
              VSpacing(),
              ReplacePoint(Id(:rplangs), @languages_term),
              VSpacing(0.5)
            ),
            HSpacing(2)
          ),
          VSpacing()
        )
      end

      @help_text = ""
      # help text (language dependent packages) - at the end of help
      @packages_help = _(
        "<p>\n" +
          "Additional packages with support for the selected primary and secondary languages will be installed. Packages no longer needed will be removed.\n" +
          "</p>"
      )

      if Stage.initial
        # help text for initial (first time) language screen
        @help_text = _(
          "<p>\n" +
            "Choose the <b>Language</b> to use during installation and for\n" +
            "the installed system.\n" +
            "</p>\n"
        )

        # help text, continued
        @help_text = Ops.add(
          @help_text,
          _(
            "<p>\n" +
              "Click <b>Next</b> to proceed to the next dialog.\n" +
              "</p>\n"
          )
        )

        # help text, continued
        @help_text = Ops.add(
          @help_text,
          _(
            "<p>\n" +
              "Nothing will happen to your computer until you confirm\n" +
              "all your settings in the last installation dialog.\n" +
              "</p>\n"
          )
        )
        if @set_default
          # help text, continued
          @help_text = Ops.add(
            @help_text,
            _(
              "<p>\n" +
                "You can select <b>Abort</b> at any time to abort the\n" +
                "installation process.\n" +
                "</p>\n"
            )
          )
        end
      else
        # different help text when called after installation
        # in an installed system
        @help_text = _(
          "<p>\n" +
            "Choose the new <b>Language</b> for your system.\n" +
            "</p>\n"
        )
      end

      if @more_languages
        # help text when "multiple languages" are suported 1/2
        @help_text = _(
          "<p>\n" +
            "Choose the new <b>Primary Language</b> for your system.\n" +
            "</p>\n"
        )

        if @adapt_term
          # help text for 'adapt keyboard checkbox'
          @help_text = Ops.add(
            @help_text,
            _(
              "<p>\n" +
                "Check <b>Adapt Keyboard Layout</b> to change the keyboard layout to the primary language.\n" +
                "Check <b>Adapt Time Zone</b> to change the current time zone according to the primary language. If the keyboard layout or time zone is already adapted to the default language setting, the respective option is disabled.\n" +
                "</p>\n"
            )
          )
        end

        # help text when "multiple languages" are suported 2/2
        @help_text = Ops.add(
          @help_text,
          _(
            "<p>\n" +
              "<b>Secondary Languages</b><br>\n" +
              "In the selection box, specify additional languages to use on your system.\n" +
              "</p>\n"
          )
        )

        @help_text = Ops.add(@help_text, @packages_help)
      end

      # Screen title for the first interactive dialog

      Wizard.SetContents(
        @heading_text,
        @contents,
        @help_text,
        Ops.get_boolean(@argmap, "enable_back", true),
        Ops.get_boolean(@argmap, "enable_next", true)
      )

      Wizard.SetDesktopTitleAndIcon("org.openSUSE.YaST.Language")

      if @more_languages
        if !Stage.initial && !Stage.firstboot
          UI.ChangeWidget(:language, :IconPath, "/usr/share/locale/l10n/")
          UI.ChangeWidget(:languages, :IconPath, "/usr/share/locale/l10n/")
        end
        UI.ChangeWidget(:language, :Items, @primary_items)
        UI.ChangeWidget(:languages, :Items, @secondary_items)
      end

      # No .desktop files in inst-sys - use icon explicitly
      Wizard.SetTitleIcon("org.openSUSE.YaST.Language") if Stage.initial || Stage.firstboot

      update_adapt_term if @adapt_term

      # Get the user input.
      #
      @ret = nil

      UI.SetFocus(Id(:language))

      # adapt keyboard for language?
      @kbd_adapt = @set_default && !Mode.config
      # adapt timezone for language?
      @tmz_adapt = @set_default && !Mode.config
      begin
        @ret = Wizard.UserInput
        Builtins.y2debug("UserInput() returned %1", @ret)

        @ret = :next if @ret == :ok

        if @ret == :abort && Popup.ConfirmAbort(:painless)
          Wizard.RestoreNextButton
          return :abort
        end

        @ret = LanguageExpertDialog() if @ret == :expert

        Wizard.ShowHelp(@help_text) if @ret == :help

        if @ret == :changed_locale
          @primary_included = false
          if nil == Builtins.find(@primary_items) do |i|
              Ops.get(i, [0, 0]) == @language
            end
            @primary_items = Builtins.add(
              @primary_items,
              Item(Id(@language), @language, true)
            )
            UI.ChangeWidget(Id(:language), :Items, @primary_items)
          end
          Language.Set(@language) if Mode.config
        end

        if @ret == :next ||
            (@ret == :language || @ret == :changed_locale) && !Mode.config
          # Get the selected language.
          #
          if @ret != :changed_locale
            @language = @more_languages ?
              Convert.to_string(UI.QueryWidget(Id(:language), :Value)) :
              Convert.to_string(UI.QueryWidget(Id(:language), :CurrentItem))
          end

          if @ret != :changed_locale && @adapt_term
            @kbd_adapt = Convert.to_boolean(
              UI.QueryWidget(Id(:adapt_kbd), :Value)
            )
            @tmz_adapt = Convert.to_boolean(
              UI.QueryWidget(Id(:adapt_tmz), :Value)
            )
          end

          if @ret == :next && !Language.CheckIncompleteTranslation(@language)
            @ret = :not_next
            next
          end
          if @ret == :next && Stage.initial
            Language.CheckLanguagesSupport(@language)
          end
          if @language != Language.language
            Builtins.y2milestone(
              "Language changed from %1 to %2",
              Language.language,
              @language
            )
            if @more_languages
              @selected_languages = Convert.convert(
                UI.QueryWidget(Id(:languages), :SelectedItems),
                :from => "any",
                :to   => "list <string>"
              )

              if @ret != :next
                Language.languages = Builtins.mergestring(
                  @selected_languages,
                  ","
                )
              end
            end


            Timezone.ResetZonemap if @set_default

            # Set it in the Language module.
            #
            Language.Set(@language)
            update_adapt_term if @adapt_term
          end

          if Stage.initial || Stage.firstboot
            if (@set_default && @ret == :language ||
                !@set_default && @ret == :next) &&
                Language.SwitchToEnglishIfNeeded(true)
              Builtins.y2debug("UI switched to en_US")
            elsif @ret == :next || @set_default && @ret == :language
              Console.SelectFont(@language)
              # no yast translation for nn_NO, use nb_NO as a backup
              if @language == "nn_NO"
                Builtins.y2milestone(
                  "Nynorsk not translated, using Bokm\u00E5l"
                )
                Language.WfmSetGivenLanguage("nb_NO")
              else
                Language.WfmSetLanguage
              end
            end
          end

          if @ret == :language && @set_default
            # Display newly translated dialog.
            Wizard.SetFocusToNextButton
            return :again
          end

          if @ret == :next
            # Language has been set already.
            # On first run store users decision as default.
            #
            if @set_default
              Builtins.y2milestone("Resetting to default language")
              Language.SetDefault
            end

            if @tmz_adapt
              Timezone.SetTimezoneForLanguage(@language)
            else
              Timezone.user_decision = true
            end

            if @kbd_adapt
              Keyboard.SetKeyboardForLanguage(@language)
              Keyboard.SetKeyboardDefault if @set_default
            else
              Keyboard.user_decision = true
            end

            if !Stage.initial && !Mode.update
              # save settings (rest is saved in LanguageWrite)
              Keyboard.Save if @kbd_adapt
              Timezone.Save if @tmz_adapt
            end
            Builtins.y2milestone(
              "Language: '%1', system encoding '%2'",
              @language,
              WFM.GetEncoding
            )

            if @more_languages || Stage.firstboot
              @selected_languages = Stage.firstboot ?
                [@language] :
                Convert.convert(
                  UI.QueryWidget(Id(:languages), :SelectedItems),
                  :from => "any",
                  :to   => "list <string>"
                )

              if !Builtins.contains(@selected_languages, @language)
                @selected_languages = Builtins.add(
                  @selected_languages,
                  Language.RemoveSuffix(@language)
                )
              end
              Builtins.y2milestone(
                "selected languages: %1",
                @selected_languages
              )

              Language.languages = Builtins.mergestring(
                @selected_languages,
                ","
              )

              # now adapt language seletions
              if Stage.initial || Mode.update
                Pkg.SetAdditionalLocales(@selected_languages)
              elsif Language.PackagesModified && !Mode.config
                if !Language.PackagesInit(@selected_languages)
                  # error message - package solver failed
                  Report.Error(_("There are unresolved package dependencies."))

                  # run the package selector

                  # disable repomanagement during installation
                  @repomgmt = !Mode.installation
                  # start the package selector
                  PackagesUI.RunPackageSelector(
                    { "enable_repo_mgr" => @repomgmt, "mode" => :summaryMode }
                  )

                  @ret = :not_next
                  next
                end
                if !Language.EnoughSpace
                  # error message
                  Report.Error(
                    _(
                      "There is not enough space to install all additional packages.\nRemove some languages from the selection."
                    )
                  )
                  @ret = :not_next
                  next
                end
                if Stage.firstboot # install language packages now
                  Language.PackagesCommit
                end
              end
            end
          end
        end
      end until @ret == :next || @ret == :back

      Convert.to_symbol(@ret)
    end

    # Popup for setting expert language values
    def LanguageExpertDialog
      # help text for langauge expert screen
      help_text = _(
        "<p>\n" +
          "Here, fine-tune settings for the language handling.\n" +
          "These settings are written into the file <tt>/etc/sysconfig/language</tt>.\n" +
          "If unsure, use the default values already selected.\n" +
          "</p>\n"
      )

      # help text for langauge expert screen
      help_text = Ops.add(
        help_text,
        # help text for langauge expert screen
        _(
          "<p>Use <b>Detailed Locale Setting</b> to set a locale for the primary language that is not offered in the list in the main dialog. Translation may not be available for the selected locale.</p>"
        )
      )

      val = Language.GetExpertValues
      val_on_entry = deep_copy(val)
      Builtins.y2debug("expert values %1", val)

      # get the list of locales for our language
      lang = Builtins.substring(@language, 0, 2)
      locales_list = []

      Builtins.foreach(Language.GetLocales) do |code, i|
        if Builtins.substring(code, 0, 2) == lang
          locales_list = Builtins.add(locales_list, code)
        end
      end
      if !Builtins.contains(locales_list, @language)
        locales_list = Builtins.add(locales_list, @language)
      end

      UI.OpenDialog(
        Opt(:decorated),
        HBox(
          HWeight(40, RichText(help_text)),
          HStretch(),
          HSpacing(),
          HWeight(
            60,
            VBox(
              HSpacing(45),
              # heading text
              Heading(_("Language Details")),
              VSpacing(Opt(:vstretch), 2),
              Left(
                # checkbox label
                CheckBox(
                  Id(:use_utf8),
                  _("Use &UTF-8 Encoding"),
                  Ops.get_boolean(val, "use_utf8", true)
                )
              ),
              VSpacing(),
              Left(
                # combo box label
                ComboBox(
                  Id(:locales),
                  _("&Detailed Locale Setting"),
                  locales_list
                )
              ),
              VSpacing(Opt(:vstretch), 7),
              ButtonBox(
                PushButton(Id(:ok), Opt(:default), Label.OKButton),
                PushButton(Id(:cancel), Opt(:key_F9), Label.CancelButton)
              ),
              VSpacing(0.5)
            )
          )
        )
      )

      UI.ChangeWidget(Id(:locales), :Value, @language)

      ret = :none
      retval = :expert
      begin
        ret = Convert.to_symbol(UI.UserInput)
        if ret == :ok
          val = {}
          Ops.set(val, "use_utf8", UI.QueryWidget(Id(:use_utf8), :Value))
          if val != val_on_entry
            Builtins.y2milestone("expert settings changed to %1", val)
            Language.SetExpertValues(val)
            Language.ExpertSettingsChanged = true
          end
          if @language !=
              Convert.to_string(UI.QueryWidget(Id(:locales), :Value))
            @language = Convert.to_string(UI.QueryWidget(Id(:locales), :Value))
            retval = :changed_locale
          end
        end
      end until ret == :cancel || ret == :ok
      UI.CloseDialog
      retval
    end

    # helper function for updating the "adapt terms" to current language
    def update_adapt_term
      kb = Keyboard.GetKeyboardForLanguage(@language, "english-us")
      tz = Timezone.GetTimezoneForLanguage(@language, "US/Mountain")
      kbd_name = Ops.get(Keyboard.Selection, kb, "")
      tmz_name = Timezone.GetTimezoneCountry(tz)

      UI.ReplaceWidget(
        Id(:rpadapt),
        VBox(
          Left(
            CheckBox(
              Id(:adapt_kbd),
              # check box label (%1 is keyboard layout name)
              Builtins.sformat(_("Adapt &Keyboard Layout to %1"), kbd_name)
            )
          ),
          Left(
            CheckBox(
              Id(:adapt_tmz),
              # check box label (%1 is country name)
              Builtins.sformat(_("Adapt &Time Zone to %1"), tmz_name)
            )
          )
        )
      )
      UI.ChangeWidget(Id(:adapt_kbd), :Enabled, kb != Keyboard.current_kbd)
      UI.ChangeWidget(Id(:adapt_tmz), :Enabled, tz != Timezone.timezone)

      nil
    end
  end
end

Yast::SelectLanguageClient.new.main

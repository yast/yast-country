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

# File:	modules/Language.ycp
# Module:	Language
# Summary:	This module does all language related stuff:
# Authors:	Klaus Kaempf <kkaempf@suse.de>
#		Thomas Roelz <tom@suse.de>
# Maintainer:  Jiri Suchomel <jsuchome@suse.cz>
#
# $Id$
require "yast"

module Yast
  class LanguageClass < Module
    DEFAULT_FALLBACK_LANGUAGE = "en_US".freeze

    include Yast::Logger

    require "y2country/language_dbus"

    def main
      Yast.import "Pkg"
      Yast.import "UI"
      textdomain "country"


      Yast.import "AsciiFile"
      Yast.import "Directory"
      Yast.import "Encoding"
      Yast.import "FileUtils"
      Yast.import "InstExtensionImage"
      Yast.import "Linuxrc"
      Yast.import "Misc"
      Yast.import "Mode"
      Yast.import "PackageCallbacks"
      Yast.import "PackageSystem"
      Yast.import "Popup"
      Yast.import "ProductFeatures"
      Yast.import "Report"
      Yast.import "SlideShow"
      Yast.import "Stage"

      # directory where all the language definitions are stored
      # it's a constant, but depends on a dynamic content (Directory)
      @languages_directory = "#{Directory.datadir}/languages"

      # currently selected language
      @language = DEFAULT_FALLBACK_LANGUAGE

      # original language
      @language_on_entry = DEFAULT_FALLBACK_LANGUAGE

      # language preselected in /etc/install.inf
      @preselected = DEFAULT_FALLBACK_LANGUAGE

      # user readable description of language
      @name = "English (US)"

      @linuxrc_language_set = false

      # Default language to be restored with MakeProposal.
      @default_language = DEFAULT_FALLBACK_LANGUAGE


      # Default settings for INSTALLED_LANGUAGES in /etc/sysconfig/language
      @languages = ""

      # Original value of INSTALLED_LANGUAGES
      @languages_on_entry = ""

      # Use utf8 in locale
      @use_utf8 = true

      # ncurses mode
      @text_mode = nil

      @ExpertSettingsChanged = false

      # Was the initial language selection skipped? (see bug 223258)
      # (It can be, if the language was selected in linuxrc)
      @selection_skipped = false

      # level of translation completeness
      @translation_status = {}

      # map (locale: 1) of available locales
      @locales = {}

      # map with all languages (cached - needs to be reread for retranslation)
      @languages_map = {}

      # mapping of language to its default (proposed) time zone
      @lang2timezone = {}

      # mapping of language to its default (proposed) kbd layout
      @lang2keyboard = {}

      # setting read from localed
      @localed_conf = {}

      # languages that cannot be correctly shown in text mode
      # if the system (Linuxrc) does not start with them from the beginning
      @cjk_languages = [
        "ja",
        "ko",
        "zh",
        "hi",
        "km",
        "pa",
        "bn",
        "gu",
        "mr",
        "si",
        "ta",
        "vi"
      ]

      # FATE #302955: Split translations out of installation system
      # [ "en_US", "en_GB", "de", "cs" ]
      @available_lang_filenames = nil

      # list of items for secondary languages term
      @secondary_items = []

      @english_names = {}

      @reset_recommended = true
      Language()
    end

    #remove the suffix, if there's any (en_US.UTF-8 -> en_US)
    def RemoveSuffix(lang)
      return lang[/[a-zA-Z_]+/]
    end

    # Check if the language is "CJK"
    # (and thus could not be shown in text mode - see bug #102958)
    def CJKLanguage(lang)
      l = Builtins.substring(lang, 0, 2)
      Builtins.contains(@cjk_languages, l)
    end

    # return the value of text_mode (true for ncurses)
    def GetTextMode
      if @text_mode == nil
        display_info = UI.GetDisplayInfo
        @text_mode = Ops.get_boolean(display_info, "TextMode", false)
      end
      @text_mode
    end

    # Read language DB: translatable strings will be translated to current language
    def read_languages_map
      Builtins.foreach(
        Convert.convert(
          SCR.Read(path(".target.dir"), @languages_directory, []),
          :from => "any",
          :to   => "list <string>"
        )
      ) do |file|
        next if !Builtins.regexpmatch(file, "language_.+\\.ycp$")
        language_map = Convert.to_map(
          Builtins.eval(
            SCR.Read(path(".target.yast2"), Ops.add("languages/", file))
          )
        )
        language_map = {} if language_map == nil
        code = file
        Builtins.foreach(
          Convert.convert(
            language_map,
            :from => "map",
            :to   => "map <string, any>"
          )
        ) do |key, val|
          if Ops.is_list?(val)
            Ops.set(@languages_map, key, Convert.to_list(val))
            code = key
          end
        end
        if !Builtins.haskey(@lang2timezone, code)
          Ops.set(
            @lang2timezone,
            code,
            Ops.get_string(language_map, "timezone", "US/Eastern")
          )
        end
        if !Builtins.haskey(@lang2keyboard, code)
          Ops.set(
            @lang2keyboard,
            code,
            Ops.get_string(language_map, "keyboard", DEFAULT_FALLBACK_LANGUAGE)
          )
        end
      end

      @languages_map = {} if @languages_map == nil

      nil
    end

    # Read only the map of one language
    # @param language code
    def ReadLanguageMap(lang)
      ret = {}

      file = Builtins.sformat("language_%1.ycp", lang)
      if FileUtils.Exists(Ops.add(Ops.add(@languages_directory, "/"), file))
        ret = Convert.to_map(
          Builtins.eval(
            SCR.Read(path(".target.yast2"), Ops.add("languages/", file))
          )
        )
        ret = {} if ret == nil
      end
      deep_copy(ret)
    end

    # Return the whole map with language descriptions
    # @param [Boolean] force force new loading of the map from the files (forces the change
    # of translations to current language)
    def GetLanguagesMap(force)
      read_languages_map if Builtins.size(@languages_map) == 0 || force
      deep_copy(@languages_map)
    end

    # Return English translation of given language (Fate 301789)
    def EnglishName(code, backup)
      if Ops.get_string(@english_names, code, "") == ""
        if @language == DEFAULT_FALLBACK_LANGUAGE
          Ops.set(@english_names, code, backup)
        else
          Builtins.y2warning("nothing in english_names...")
        end
      end
      Ops.get_string(@english_names, code, backup)
    end

    # Fill the map with English names of languages
    def FillEnglishNames(lang)
      return if lang == DEFAULT_FALLBACK_LANGUAGE # will be filled in on first start
      if @use_utf8
        WFM.SetLanguage(DEFAULT_FALLBACK_LANGUAGE, "UTF-8")
      else
        WFM.SetLanguage(DEFAULT_FALLBACK_LANGUAGE)
      end
      Builtins.foreach(GetLanguagesMap(true)) do |code, info|
        Ops.set(@english_names, code, Ops.get_string(info, 4, ""))
      end
      if @use_utf8
        WFM.SetLanguage(lang, "UTF-8")
      else
        WFM.SetLanguage(lang)
      end

      nil
    end


    # return the content of lang2timezone map
    # (mapping of languages to their default (proposed) time zones)
    def GetLang2TimezoneMap(force)
      read_languages_map if Builtins.size(@languages_map) == 0 && force
      deep_copy(@lang2timezone)
    end

    # return the content of lang2keyboard map
    # (mapping of languages to their default (proposed) keyboard layouts)
    def GetLang2KeyboardMap(force)
      read_languages_map if Builtins.size(@languages_map) == 0 && force
      deep_copy(@lang2keyboard)
    end

    # return the map of all supported countries and language codes
    def GetLocales
      if @locales == nil || @locales == {}
        out = Convert.to_map(
          SCR.Execute(path(".target.bash_output"), "/usr/bin/locale -a")
        )
        Builtins.foreach(
          Builtins.splitstring(Ops.get_string(out, "stdout", ""), "\n")
        ) do |l|
          pos = Builtins.findfirstof(l, ".@")
          if pos != nil && Ops.greater_or_equal(pos, 0)
            l = Builtins.substring(l, 0, pos)
          end
          Ops.set(@locales, l, 1) if l != ""
        end
      end

      deep_copy(@locales)
    end

    # For given language, return the file name of language extension (image)
    # to be downloaded to the inst-sys
    # (FATE #302955: Split translations out of installation system)
    def GetLanguageExtensionFilename(language)
      if @available_lang_filenames == nil
        lang_numbers = {}
        Builtins.foreach(GetLanguagesMap(false)) do |code, data|
          short = Ops.get(Builtins.splitstring(code, "_"), 0, "")
          if Ops.get(lang_numbers, short, 0) == 0
            Ops.set(lang_numbers, short, 1)
          else
            Ops.set(
              lang_numbers,
              short,
              Ops.add(Ops.get(lang_numbers, short, 0), 1)
            )
          end
        end
        @available_lang_filenames = Builtins.maplist(GetLanguagesMap(false)) do |code, data|
          short = Ops.get(Builtins.splitstring(code, "_"), 0, "")
          if Ops.greater_than(Ops.get(lang_numbers, short, 0), 1)
            next code
          else
            next short
          end
        end
      end

      check_for_languages = [language]

      # 'en_US' ? add also 'en'
      if Ops.greater_than(Builtins.size(language), 2)
        check_for_languages = Builtins.add(
          check_for_languages,
          Ops.get(Builtins.splitstring(language, "_"), 0, "")
        )
      end

      # Default fallback
      filename = "yast2-trans-en_US.rpm"

      Builtins.foreach(check_for_languages) do |one_language|
        if Builtins.contains(@available_lang_filenames, one_language)
          filename = Builtins.sformat("yast2-trans-%1.rpm", one_language)
          raise Break
        end
      end
      # yast2-trans-pt.rpm doesn't fit into the algorithm above, see bnc#386298
      return "yast2-trans-pt.rpm" if language == "pt_PT"

      Builtins.y2milestone("Using %1 for %2", filename, language)
      filename
    end

    # Downloads inst-sys extension for a given language
    # including giving a UI feedback to the user
    #
    # @param [String] language, e.g. 'de_DE'
    def integrate_inst_sys_extension(language)
      log.info "integrating translation extension..."

      # busy message
      Popup.ShowFeedback(
        "",
        _("Downloading installation system language extension...")
      )

      InstExtensionImage.DownloadAndIntegrateExtension(
        GetLanguageExtensionFilename(language)
      )

      Popup.ClearFeedback
      log.info "integrating translation extension... done"
    end

    # Returns whether the given language string is supported by this library.
    #
    # @param [String] language
    # @see @languages_directory
    def valid_language?(language)
      GetLanguagesMap(false).key?(language)
    end

    # Checks whether given language is supported by the installer
    # and changes it to the default language en_US if it isn't.
    #
    # @param language [String] reference to the new language
    # @param error_report [Boolean] showing an error popup
    # @return [String] new (corrected) language
    def correct_language(language, error_report: true)
      # No correction needed, this is already a correct language definition
      return language if valid_language?(language)

      # TRANSLATORS: Error message. Strings marked %{...} will be replaced
      # with variable content - do not translate them, please.
      Report.Error(
        _("Language '%{language}' was not found within the list of supported languages\n" +
          "available at %{directory}.\n\nFallback language %{fallback} will be used."
        ) % {
          :language => language,
          :directory => @languages_directory,
          :fallback => DEFAULT_FALLBACK_LANGUAGE
        }
      ) if error_report

      return DEFAULT_FALLBACK_LANGUAGE
    end

    # Changes the install.inf in inst-sys according to newly selected language
    #
    # FIXME: code just moved, refactoring needed
    def adapt_install_inf
      yinf = {}
      yinf_ref = arg_ref(yinf)
      AsciiFile.SetDelimiter(yinf_ref, " ")
      yinf = yinf_ref.value
      yinf_ref = arg_ref(yinf)
      AsciiFile.ReadFile(yinf_ref, "/etc/yast.inf")
      yinf = yinf_ref.value
      lines = AsciiFile.FindLineField(yinf, 0, "Language:")

      if Ops.greater_than(Builtins.size(lines), 0)
        yinf_ref = arg_ref(yinf)
        AsciiFile.ChangeLineField(
          yinf_ref,
          Ops.get_integer(lines, 0, -1),
          1,
          @language
        )
        yinf = yinf_ref.value
      else
        yinf_ref = arg_ref(yinf)
        AsciiFile.AppendLine(yinf_ref, ["Language:", @language])
        yinf = yinf_ref.value
      end

      yinf_ref = arg_ref(yinf)
      AsciiFile.RewriteFile(yinf_ref, "/etc/yast.inf")
      yinf = yinf_ref.value
    end

    # Set module to selected language.
    #
    # @param [String] lang language string ISO code of language
    def Set(lang)
      lang = deep_copy(lang)

      Builtins.y2milestone(
        "original language: %1; setting to lang:%2",
        @language,
        lang
      )

      if @language != lang
        lang = correct_language(lang)

        if Stage.initial && !Mode.test && !Mode.live_installation
          integrate_inst_sys_extension(lang)
        end

        GetLocales() if Builtins.size(@locales) == 0

        language_def = GetLanguagesMap(false).fetch(lang, [])
        # In config mode, use language name translated into the current language
        # othewrwise use the language name translated into that selected language
        # because the whole UI will get translated later too
        @name = (Mode.config ? language_def[4] : language_def[0]) || lang
        @language = lang
        Encoding.SetEncLang(@language)
      end

      if Stage.initial && !Mode.test
        adapt_install_inf

        # update "name" for proposal when it cannot be shown correctly
        if GetTextMode() && CJKLanguage(lang) && !CJKLanguage(@preselected)
          @name = GetLanguagesMap(false).fetch(lang, [])[1] || lang
        end
      end

      nil
    end


    # Set the language that was read from sysconfig,
    # read only one needed language file
    def QuickSet(lang)
      Builtins.y2milestone(
        "original language: %1; setting to lang:%2",
        @language,
        lang
      )

      if @language != lang
        lang_map = ReadLanguageMap(lang)
        @name = Ops.get_string(lang_map, [lang, 0], lang)
        @language = lang
        Encoding.SetEncLang(@language)
      end

      nil
    end

    def LinuxrcLangSet
      @linuxrc_language_set
    end

    # generate the whole locale string for given language according to DB
    # (e.g. de_DE -> de_DE.UTF-8)
    def GetLocaleString(lang)

      # if the suffix is already there, do nothing
      return lang if lang.count(".@") > 0

      read_languages_map if Builtins.size(@languages_map) == 0

      language_info = Ops.get(@languages_map, lang, [])
      if !Builtins.haskey(@languages_map, lang)
        language_info = [lang, lang, ".UTF-8"]
      end

      # full language code
      idx = @use_utf8 ? 2 : 3
      val = lang + (language_info[idx] || "")

      Builtins.y2milestone("locale %1", val)
      val
    end


    # Store current language as default language.
    def SetDefault
      Builtins.y2milestone("Setting default language: %1", @language)
      @default_language = @language
      nil
    end

    def ReadLocaleConfLanguage
      return nil if Mode.testsuite
      @localed_conf  = Y2Country.read_locale_conf
      return nil if @localed_conf.nil?
      local_lang = @localed_conf["LANG"]
      pos = Builtins.findfirstof(local_lang, ".@")

      if pos != nil && Ops.greater_or_equal(pos, 0)
        local_lang = Builtins.substring(local_lang, 0, pos)
      end

      log.info("language from sysconfig: %{local_lang}")
      local_lang
    end

    # Read the RC_LANG value from sysconfig and exctract language from it
    # @return language
    def ReadSysconfigLanguage
      local_lang = Misc.SysconfigRead(
        path(".sysconfig.language.RC_LANG"),
        @language
      )

      pos = Builtins.findfirstof(local_lang, ".@")

      if pos != nil && Ops.greater_or_equal(pos, 0)
        local_lang = Builtins.substring(local_lang, 0, pos)
      end

      Builtins.y2milestone("language from sysconfig: %1", local_lang)
      local_lang
    end

    # Read the rest of language values from sysconfig
    def ReadSysconfigValues
      # during live installation, we have sysconfig.language.RC_LANG available
      if !Stage.initial || Mode.live_installation
        val = Builtins.toupper(
          Misc.SysconfigRead(path(".sysconfig.language.RC_LANG"), "")
        )
        @use_utf8 = Builtins.search(val, ".UTF-8") != nil if val != ""
      else
        @use_utf8 = true
      end
      @languages = Misc.SysconfigRead(
        path(".sysconfig.language.INSTALLED_LANGUAGES"),
        ""
      )

      nil
    end

    def ReadUtf8Setting
      return nil if Mode.testsuite
      # during live installation, we have sysconfig.language.RC_LANG available
      if !Stage.initial || Mode.live_installation
        @localed_conf  = Y2Country.read_locale_conf
        return nil if @localed_conf.nil?
        local_lang = @localed_conf["LANG"]
        @use_utf8 = Builtins.search(local_lang, ".UTF-8") != nil unless local_lang.empty?
      else
        @use_utf8 = true
      end
      log.info("Use UTF-8: #{@use_utf8}")
    end

    # Constructor
    #
    # Initializes module either from /etc/install.inf
    # or from /etc/sysconfig/language
    def Language
      if Mode.config
        # read the translated name: bug #180633
        read_languages_map
        @name = Ops.get_string(@languages_map, [@language, 4], @language)
        return
      end

      if Stage.initial && !Mode.live_installation
        lang = ProductFeatures.GetStringFeature("globals", "language")
        Builtins.y2milestone("product LANGUAGE %1", lang)

        @preselected = Linuxrc.InstallInf("Locale")
        Builtins.y2milestone("install_inf Locale %1", @preselected)
        if @preselected != nil && @preselected != ""
          lang = @preselected
          @linuxrc_language_set = true if lang != DEFAULT_FALLBACK_LANGUAGE
        else
          @preselected = DEFAULT_FALLBACK_LANGUAGE
        end

        lang ||= ""
        Builtins.y2milestone("lang after checking /etc/install.inf: %1", lang)
        if lang == ""
          # As language has not been set we are trying to ask libzypp.
          # But libzypp can also returns languages which we do not support
          # (e.g. default "en"). So we are checking and changing it to default
          # if needed (without showing an error (bnc#1009508))
          lang = correct_language(Pkg.GetTextLocale, error_report: false)
          Builtins.y2milestone("setting lang to default language: %1", lang)
        end
        # Ignore any previous settings and take language from control file.
        l = ProductFeatures.GetStringFeature("globals", "language")
        if l != nil && l != ""
          lang = l
          Builtins.y2milestone(
            "setting lang to ProductFeatures::language: %1",
            lang
          )
        end
        FillEnglishNames(lang)
        Set(lang) # coming from /etc/install.inf
        SetDefault() # also default
      else
        local_lang = ReadLocaleConfLanguage() || ReadSysconfigLanguage()
        QuickSet(local_lang)
        SetDefault() # also default
        if Mode.live_installation || Stage.firstboot
          FillEnglishNames(local_lang)
        end
      end
      if Ops.greater_than(
          SCR.Read(path(".target.size"), "/etc/sysconfig/language"),
          0
        )
        ReadSysconfigValues()
        ReadUtf8Setting()
      end
      Encoding.SetUtf8Lang(@use_utf8)

      nil
    end

    # Store the inital values; in normal mode, read from system was done in constructor
    # @param [Boolean] really: also read the values from the system
    def Read(really)
      if really
        Set(ReadLocaleConfLanguage() || ReadSysconfigLanguage())
        ReadSysconfigValues()
        ReadUtf8Setting()
      end

      @language_on_entry = @language
      @languages_on_entry = @languages

      Builtins.y2milestone(
        "language: %1, languages: %2",
        @language_on_entry,
        @languages_on_entry
      )

      @ExpertSettingsChanged = false

      true
    end

    # was anything modified?
    def Modified
      @language != @language_on_entry || @ExpertSettingsChanged ||
        Builtins.sort(Builtins.splitstring(@languages, ",")) !=
          Builtins.sort(Builtins.splitstring(@languages_on_entry, ","))
    end

    # Does the modification of language(s) require installation of new packages?
    # This test compares the list of original languages (primary+secondary) with
    # the list after user's modifications
    def PackagesModified
      Builtins.sort(
        Builtins.union(Builtins.splitstring(@languages, ","), [@language])
      ) !=
        Builtins.sort(
          Builtins.union(
            Builtins.splitstring(@languages_on_entry, ","),
            [@language_on_entry]
          )
        )
    end

    # GetExpertValues()
    #
    # Return the values for the various expert settings in a map
    #
    # @param       -
    #
    # @return  [Hash] with values filled in
    #
    def GetExpertValues
      { "use_utf8" => @use_utf8 }
    end

    # SetExpertValues()
    #
    # Set the values of the various expert setting
    #
    # @param [Hash] val     map with new values of expert settings
    #
    # @return  [void]
    #
    def SetExpertValues(val)
      val = deep_copy(val)
      if Builtins.haskey(val, "use_utf8")
        @use_utf8 = Ops.get_boolean(val, "use_utf8", false)
        Encoding.SetUtf8Lang(@use_utf8)
      end

      nil
    end

    # WfmSetLanguag()
    #
    # Set the given language in WFM and UI
    #
    # @param       language (could be different from current in CJK case)
    #
    # @return      -
    def WfmSetGivenLanguage(lang)
      return if Mode.config

      encoding = @use_utf8 ? "UTF-8" : Encoding.console

      Builtins.y2milestone(
        "language %1 enc %2 utf8:%3",
        lang,
        encoding,
        @use_utf8
      )

      UI.SetLanguage(lang, encoding)

      if @use_utf8
        WFM.SetLanguage(lang, "UTF-8")
      else
        WFM.SetLanguage(lang)
      end

      nil
    end


    # WfmSetLanguag()
    #
    # Set the current language in WFM and UI
    #
    # @param       -
    #
    # @return      -
    def WfmSetLanguage
      WfmSetGivenLanguage(@language)

      nil
    end


    # Return proposal string.
    #
    # @return	[String]	user readable description.
    #		If force_reset is true reset the module to the language
    #		stored in default_language.
    def MakeProposal(force_reset, language_changed)
      Builtins.y2milestone("force_reset: %1", force_reset)
      Builtins.y2milestone("language_changed: %1", language_changed)

      if force_reset
        Set(@default_language) # reset
      end
      ret = [
        # summary label
        Builtins.sformat(_("Primary Language: %1"), @name)
      ]
      if Builtins.size(@languages_map) == 0 || language_changed
        read_languages_map
      end
      # maybe additional languages were selected in package selector (bnc#393007)
      langs = Builtins.splitstring(@languages, ",")
      missing = []
      Builtins.foreach(Pkg.GetAdditionalLocales) do |additional|
        # add the language for both kind of values ("cs" vs. "pt_PT")
        if !Builtins.contains(langs, additional)
          additional = DEFAULT_FALLBACK_LANGUAGE if additional == "en"
          additional = "pt_PT" if additional == "pt"
          if Builtins.haskey(@languages_map, additional)
            missing = Builtins.add(missing, additional)
            next
          end
          if Builtins.contains(langs, additional) #en_US or pt_PT already installed
            next
          end
          # now, let's hope there's only one full entry for the short one
          # (e.g. cs_CZ for cs)
          Builtins.foreach(@languages_map) do |k, dummy|
            if Builtins.substring(k, 0, 2) == additional
              missing = Builtins.add(missing, k)
              raise Break
            end
          end
        end
      end
      if Ops.greater_than(Builtins.size(missing), 0)
        langs = Convert.convert(
          Builtins.union(langs, missing),
          :from => "list",
          :to   => "list <string>"
        )
        @languages = Builtins.mergestring(langs, ",")
      end
      # now, generate the summary strings
      if @languages != "" && @languages != @language
        langs = []
        Builtins.foreach(Builtins.splitstring(@languages, ",")) do |lang|
          if lang != @language
            l = Ops.get_string(
              @languages_map,
              [lang, 4],
              Ops.get_string(@languages_map, [lang, 0], "")
            )
            langs = Builtins.add(langs, l) if l != ""
          end
        end
        if Ops.greater_than(Builtins.size(langs), 0)
          # summary label
          ret = Builtins.add(
            ret,
            Builtins.sformat(
              _("Additional Languages: %1"),
              Builtins.mergestring(langs, ", ")
            )
          )
        end
      end
      deep_copy(ret)
    end

    # Return 'simple' proposal string.
    # @return [String] preformated description.
    def MakeSimpleProposal
      Yast.import "HTML"

      ret = [
        # summary label
        Builtins.sformat(_("Primary Language: %1"), @name)
      ]
      if @languages != "" && @languages != @language
        langs = []
        Builtins.foreach(Builtins.splitstring(@languages, ",")) do |lang|
          if lang != @language
            l = Ops.get_string(
              @languages_map,
              [lang, 4],
              Ops.get_string(@languages_map, [lang, 0], "")
            )
            langs = Builtins.add(langs, l) if l != ""
          end
        end
        if Ops.greater_than(Builtins.size(langs), 0)
          # summary label
          ret = Builtins.add(
            ret,
            Builtins.sformat(_("Additional Languages: %1"), HTML.List(langs))
          )
        end
      end
      HTML.List(ret)
    end

    # return user readable description of language
    def GetName
      @name
    end

    # Return a map of ids and names to build up a selection list
    # for the user. The key is used later in the Set function
    # to select this language. The name is a translated string.
    #
    # @return [Hash] of $[ language : [ utf8-name, ascii-name] ...]
    #			for all known languages
    #			'language' is the (2 or 5 char)  ISO language code.
    #			'utf8-name' is a user-readable (UTF-8 encoded !) string.
    #			'ascii-name' is an english (ascii encoded !) string.
    # @see #Set
    def Selection
      read_languages_map

      Builtins.mapmap(@languages_map) do |code, data|
        {
          code => [
            Ops.get_string(data, 0, ""),
            Ops.get_string(data, 1, ""),
            Ops.get_string(data, 4, Ops.get_string(data, 0, ""))
          ]
        }
      end
    end


    # Save state to target.
    def Save
      loc = GetLocaleString(@language)

      SCR.Write(path(".sysconfig.language.RC_LANG"), nil) # wipe the variable

      if Builtins.find(loc, "zh_HK") == 0
        @localed_conf["LC_MESSAGES"] = "zh_TW"
      elsif @localed_conf["LC_MESSAGES"] == "zh_TW"
        # FIXME ugly hack: see bug #47711
        @localed_conf.delete("LC_MESSAGES")
      end

      SCR.Write(path(".sysconfig.language.ROOT_USES_LANG"), nil) # wipe the variable
      SCR.Write(path(".sysconfig.language.INSTALLED_LANGUAGES"), @languages)
      SCR.Write(path(".sysconfig.language"), nil)

      @localed_conf["LANG"] = loc
      log.info("Locale: #{@localed_conf}")
      locale_out1 = @localed_conf.map do | key, val |
        "#{key}=#{val}"
      end
      log.info("Locale: #{locale_out1}")
      locale_out=locale_out1.join(",")
      log.info("Locale: #{locale_out}")

      cmd = if Stage.initial
        # do not use --root option, SCR.Execute(".target...") already runs in chroot
        "/usr/bin/systemd-firstboot --root '#{Installation.destdir}' --locale '#{loc}'"
      else
        # this sets both the console and the X11 keyboard (see "man localectl")
        "/usr/bin/localectl set-locale #{locale_out}"
      end
      log.info "Making language setting persistent: #{cmd}"
      result = if Stage.initial
        WFM.Execute(path(".local.bash_output"), cmd)
      else
        SCR.Execute(path(".target.bash_output"), cmd)
      end
      if result["exit"] != 0
        # TRANSLATORS: the "%s" is replaced by the executed command
        Report.Error(_("Could not save the language setting, the command\n%s\nfailed.") % cmd)
        log.error "Language configuration not written. Failed to execute '#{cmd}'"
        log.error "output: #{result.inspect}"
      else
        log.info "output: #{result.inspect}"
      end

      Builtins.y2milestone("Saved data for language: <%1>", loc)

      nil
    end

    # unselect all selected packages (bnc#439373)
    #
    # this is a workaround for installing recommened packages for already
    # installed packages - we cannot simply set the solver flag
    # as the laguage packages are also recommended, this would cause that
    # no language package would be installed
    #
    # do this just once at the beginning
    def ResetRecommendedPackages
      return if !@reset_recommended

      Pkg.PkgSolve(true)

      selected_packages = Pkg.ResolvableProperties("", :package, "")

      Builtins.y2milestone("Unselecting already recommended packages")

      # unselect them
      Builtins.foreach(selected_packages) do |package|
        if Ops.get_symbol(package, "status", :unknown) == :selected
          Builtins.y2milestone(
            "Unselecting package: %1",
            Ops.get_string(package, "name", "")
          )
          Pkg.PkgNeutral(Ops.get_string(package, "name", ""))
        end
      end 


      @reset_recommended = false

      nil
    end

    # Initializes source and target,
    # computes the packages necessary to install and uninstall,
    # @return false if the solver failed (unresolved dependencies)
    def PackagesInit(selected_languages)
      selected_languages = deep_copy(selected_languages)
      PackageSystem.EnsureSourceInit
      PackageSystem.EnsureTargetInit

      solver_flags_backup = Pkg.GetSolverFlags
      # first, do not ignore recommended (= also language) packages
      Pkg.SetSolverFlags({ "ignoreAlreadyRecommended" => false })
      # ... but skip non-language recommended packages
      ResetRecommendedPackages()

      Pkg.SetAdditionalLocales(selected_languages)

      # now, add only recommended language packages (other recommended are PkgNeutral-ized)
      solved = Pkg.PkgSolve(true)

      Pkg.SetSolverFlags(solver_flags_backup)

      solved
    end

    # checks for disk space (#50745)
    # @return false when there is not enough disk space for new packages
    def EnoughSpace
      ok = true
      Builtins.foreach(Pkg.TargetGetDU) do |mountpoint, usage|
        if Ops.greater_than(Ops.get(usage, 2, 0), Ops.get(usage, 0, 0))
          ok = false
        end
      end
      ok
    end

    # Install and uninstall packages selected by Pkg::SetAdditionalLocales
    def PackagesCommit
      if !Mode.commandline
        # work-around for following in order not to depend on yast2-packager
        #        PackageSlideShow::InitPkgData (false);
        #               "value" : PackageSlideShow::total_size_to_install / 1024 , // kilobytes
        total_sizes_per_cd_per_src = Pkg.PkgMediaSizes
        total_size_to_install = 0
        Builtins.foreach(Builtins.flatten(total_sizes_per_cd_per_src)) do |item|
          if item != -1
            total_size_to_install = Ops.add(total_size_to_install, item)
          end
        end

        SlideShow.Setup(
          [
            {
              "name"        => "packages",
              "description" => _("Installing Packages..."),
              "value"       => Ops.divide(total_size_to_install, 1024), # kilobytes
              "units"       => :kb
            }
          ]
        )

        SlideShow.ShowTable

        SlideShow.OpenDialog
        SlideShow.MoveToStage("packages")
      end
      Pkg.PkgCommit(0)
      SlideShow.CloseDialog if !Mode.commandline
      true
    end

    # de_DE@UTF-8 -> "DE"
    # @return country part of language
    def GetGivenLanguageCountry(lang)
      country = lang

      country = @default_language if country == nil || country == ""
      if country != nil && country != ""
        if Builtins.find(country, "@") != -1
          country = Ops.get(Builtins.splitstring(country, "@"), 0, "")
        end
      end
      if country != nil && country != ""
        if Builtins.find(country, ".") != -1
          country = Ops.get(Builtins.splitstring(country, "."), 0, "")
        end
      end
      if country != nil && country != ""
        if Builtins.find(country, "_") != -1
          country = Ops.get(Builtins.splitstring(country, "_"), 1, "")
        else
          country = Builtins.toupper(country)
        end
      end

      Builtins.y2debug("country=%1", country)
      country
    end


    # de_DE@UTF-8 -> "DE"
    # @return country part of language
    def GetLanguageCountry
      GetGivenLanguageCountry(@language)
    end


    # Returns true if translation for given language is not complete
    def IncompleteTranslation(lang)
      if !Builtins.haskey(@translation_status, lang)
        file = Ops.add(Ops.add("/usr/lib/YaST2/trans/", lang), ".status")
        if !FileUtils.Exists(file)
          ll = Ops.get(Builtins.splitstring(lang, "_"), 0, "")
          if ll != ""
            file = Ops.add(Ops.add("/usr/lib/YaST2/trans/", ll), ".status")
          end
        end

        status = Convert.to_string(SCR.Read(path(".target.string"), file))

        if status != nil && status != ""
          to_i = Builtins.tointeger(status)
          Ops.set(@translation_status, lang, to_i != nil ? to_i : 0)
        else
          Ops.set(@translation_status, lang, 100)
        end
      end
      treshold = Builtins.tointeger(
        ProductFeatures.GetStringFeature(
          "globals",
          "incomplete_translation_treshold"
        )
      )
      treshold = 95 if treshold == nil

      Ops.less_than(Ops.get(@translation_status, lang, 0), treshold)
    end

    # Checks if translation is complete and displays
    # Continue/Cancel popup messsage if it is not
    # return true if translation is OK or user agrees with the warning
    def CheckIncompleteTranslation(lang)
      if IncompleteTranslation(@language)
        # continue/cancel message
        return Popup.ContinueCancel(
          _(
            "Translation of the primary language is not complete.\nSome texts may be displayed in English.\n"
          )
        )
      end
      true
    end

    # AutoYaST interface function: Get the Language configuration from a map.
    # @param [Hash] settings imported map
    # @return success
    def Import(settings)
      settings = deep_copy(settings)
      Read(false) if @languages_on_entry == "" # only save original values

      Set(Ops.get_string(settings, "language", @language))
      @languages = Ops.get_string(settings, "languages", @languages)

      SetExpertValues(settings)

      llanguages = Builtins.splitstring(@languages, ",")
      if !Builtins.contains(llanguages, @language)
        llanguages = Builtins.add(llanguages, RemoveSuffix(@language))
        @languages = Builtins.mergestring(llanguages, ",")
      end
      # set the language dependent packages to install
      if Mode.autoinst
        Pkg.SetPackageLocale(@language)
        Pkg.SetAdditionalLocales(Builtins.splitstring(@languages, ","))
      end

      true
    end

    # AutoYaST interface function: Return the Language configuration as a map.
    # @return [Hash] with the settings
    def Export
      ret = { "language" => @language, "languages" => @languages }
      Ops.set(ret, "use_utf8", @use_utf8) if !@use_utf8
      deep_copy(ret)
    end

    # AutoYaST interface function: Return the summary of Language configuration as a map.
    # @return summary string
    def Summary
      MakeSimpleProposal()
    end

    # kind: `first_screen, `primary, `secondary
    def GetLanguageItems(kind)
      ret = []

      # already generated in previous run with `primary
      if kind == :secondary && @secondary_items != []
        return deep_copy(@secondary_items)
      end
      @secondary_items = []

      use_ascii = GetTextMode()

      en_name_sort = Builtins.mapmap(Selection()) do |code, info|
        english = EnglishName(code, Ops.get_string(info, 2, code))
        { english => [Ops.get_string(info, use_ascii ? 1 : 0, ""), code] }
      end
      if kind == :first_screen
        # fate 301789
        # English name of language (translated language).
        # e.g. German (Deutsch)
        ret = Builtins.maplist(en_name_sort) do |name, codelist|
          label = Builtins.substring(Ops.get_string(codelist, 1, ""), 0, 2) == "en" ?
            Ops.get_string(codelist, 0, "") :
            Builtins.sformat("%1 - %2", name, Ops.get_string(codelist, 0, ""))
          Item(Id(Ops.get_string(codelist, 1, "")), label)
        end
        return deep_copy(ret)
      end
      # sort language by ASCII with help of a map
      # $[ "ascii-name" : [ "user-readable-string", "code" ], ...]
      # the "user-readable-string" is either ascii or utf8, depending
      # on textmode probed above (workaround because there isn't any
      # usable console font for all languages).

      languageselsort = Builtins.mapmap(Selection()) do |lang_code, lang_info|
        key = Ops.get_string(lang_info, 1, lang_code)
        {
          key => [
            Ops.get_string(lang_info, use_ascii ? 1 : 0, ""),
            lang_code,
            Ops.get_string(lang_info, 2, key)
          ]
        }
      end

      # mapping of language name (translated) to language code
      lang2code = {}
      # mapping language code to native form
      code2native = {}
      # list of language names (translated)
      lang_list = []
      Builtins.foreach(languageselsort) do |name, codelist|
        Ops.set(
          lang2code,
          Ops.get_string(codelist, 2, ""),
          Ops.get_string(codelist, 1, "")
        )
        lang_list = Builtins.add(lang_list, Ops.get_string(codelist, 2, ""))
        Ops.set(
          code2native,
          Ops.get_string(codelist, 1, ""),
          Ops.get_string(codelist, 0, "")
        )
      end


      if Stage.firstboot
        # show also native forms in firstboot (bnc#492812)
        ret = Builtins.maplist(en_name_sort) do |name, codelist|
          code = Ops.get_string(codelist, 1, "")
          label = Builtins.substring(code, 0, 2) == "en" ?
            Ops.get_string(codelist, 0, "") :
            Builtins.sformat("%1 - %2", name, Ops.get_string(codelist, 0, ""))
          Item(Id(code), label, @language == code)
        end
        return deep_copy(ret)
      end
      primary_included = false

      if kind == :primary || kind == :secondary
        languages_l = Builtins.splitstring(@languages, ",")
        # filter the primary language from the list of secondary ones:
        languages_l = Builtins.filter(languages_l) { |l| l != @language }

        icons = !(Stage.initial || Stage.firstboot)
        primary_items = []
        @secondary_items = Builtins.maplist(Builtins.lsort(lang_list)) do |trans_lang|
          code = Ops.get_string(lang2code, trans_lang, "")
          show_lang = @language == code ?
            trans_lang :
            Builtins.sformat(
              "%1 - %2",
              trans_lang,
              Ops.get_string(code2native, code, "")
            )
          primary_items = Builtins.add(
            primary_items,
            icons ?
              Item(
                Id(code),
                term(
                  :icon,
                  Ops.add(
                    Builtins.tolower(GetGivenLanguageCountry(code)),
                    "/flag.png"
                  )
                ),
                show_lang,
                @language == code
              ) :
              Item(Id(code), trans_lang, @language == code)
          )
          primary_included = true if @language == code
          icons ?
            Item(
              Id(code),
              term(
                :icon,
                Ops.add(
                  Builtins.tolower(GetGivenLanguageCountry(code)),
                  "/flag.png"
                )
              ),
              trans_lang,
              Builtins.contains(languages_l, code)
            ) :
            Item(Id(code), trans_lang, Builtins.contains(languages_l, code))
        end
        if !primary_included
          primary_items = Builtins.add(
            primary_items,
            Item(Id(@language), @language, true)
          )
        end
        ret = kind == :primary ? primary_items : @secondary_items
      end
      deep_copy(ret)
    end

    # check if selected language has support on media (F301238)
    # show a warning when not
    # @deprecated does nothing
    def CheckLanguagesSupport(_selected_language)
      log.warn "Called check for language support, but it does nothing"
      return
    end

    # Set current YaST language to English if method for showing text in
    # current language is not supported (usually for CJK languages)
    # See http://bugzilla.novell.com/show_bug.cgi?id=479529 for discussion
    # @boolean show_popup if information popup about the change should be shown
    # @return true if UI language was changed
    def SwitchToEnglishIfNeeded(show_popup)
      if Stage.normal
        Builtins.y2milestone("no language switching in normal stage")
        return false
      end
      if GetTextMode() &&
          # current language is CJK
          CJKLanguage(@language) &&
          # fbiterm is not running
          Builtins.getenv("TERM") != "iterm"
        if show_popup
          # popup message (user selected CJK language in text mode)
          Popup.Message(
            _(
              "The selected language cannot be used in text mode. English is used for\ninstallation, but the selected language will be used for the new system."
            )
          )
        end
        WfmSetGivenLanguage(DEFAULT_FALLBACK_LANGUAGE)
        return true
      end
      false
    end

    publish :variable => :language, :type => "string"
    publish :variable => :language_on_entry, :type => "string"
    publish :variable => :preselected, :type => "string"
    publish :variable => :languages, :type => "string"
    publish :variable => :languages_on_entry, :type => "string"
    publish :variable => :ExpertSettingsChanged, :type => "boolean"
    publish :variable => :selection_skipped, :type => "boolean"
    publish :variable => :available_lang_filenames, :type => "list <string>"
    publish :function => :RemoveSuffix, :type => "string (string)"
    publish :function => :CJKLanguage, :type => "boolean (string)"
    publish :function => :GetTextMode, :type => "boolean ()"
    publish :function => :GetLanguagesMap, :type => "map <string, list> (boolean)"
    publish :function => :GetLang2TimezoneMap, :type => "map <string, string> (boolean)"
    publish :function => :GetLang2KeyboardMap, :type => "map <string, string> (boolean)"
    publish :function => :GetLocales, :type => "map <string, integer> ()"
    publish :function => :Set, :type => "void (string)"
    publish :function => :QuickSet, :type => "void (string)"
    publish :function => :LinuxrcLangSet, :type => "boolean ()"
    publish :function => :GetLocaleString, :type => "string (string)"
    publish :function => :SetDefault, :type => "void ()"
    publish :function => :ReadSysconfigLanguage, :type => "string ()"
    publish :function => :ReadSysconfigValues, :type => "void ()"
    publish :function => :Language, :type => "void ()"
    publish :function => :Read, :type => "boolean (boolean)"
    publish :function => :Modified, :type => "boolean ()"
    publish :function => :PackagesModified, :type => "boolean ()"
    publish :function => :GetExpertValues, :type => "map ()"
    publish :function => :SetExpertValues, :type => "void (map)"
    publish :function => :WfmSetGivenLanguage, :type => "void (string)"
    publish :function => :WfmSetLanguage, :type => "void ()"
    publish :function => :MakeProposal, :type => "list <string> (boolean, boolean)"
    publish :function => :MakeSimpleProposal, :type => "string ()"
    publish :function => :GetName, :type => "string ()"
    publish :function => :Selection, :type => "map <string, list> ()"
    publish :function => :Save, :type => "void ()"
    publish :function => :PackagesInit, :type => "boolean (list <string>)"
    publish :function => :EnoughSpace, :type => "boolean ()"
    publish :function => :PackagesCommit, :type => "boolean ()"
    publish :function => :GetGivenLanguageCountry, :type => "string (string)"
    publish :function => :GetLanguageCountry, :type => "string ()"
    publish :function => :IncompleteTranslation, :type => "boolean (string)"
    publish :function => :CheckIncompleteTranslation, :type => "boolean (string)"
    publish :function => :Import, :type => "boolean (map)"
    publish :function => :Export, :type => "map ()"
    publish :function => :Summary, :type => "string ()"
    publish :function => :GetLanguageItems, :type => "list <term> (symbol)"
    publish :function => :CheckLanguagesSupport, :type => "void (string)"
    publish :function => :SwitchToEnglishIfNeeded, :type => "boolean (boolean)"
  end

  Language = LanguageClass.new
  Language.main
end

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

# File:		language_proposal.ycp
#
# $Id$
#
# Author:		Klaus Kaempf <kkaempf@suse.de>
#
# Purpose:		Proposal function dispatcher - language.
#
#			See also file proposal-API.txt for details.
module Yast
  class LanguageProposalClient < Client
    def main
      textdomain "country"

      Yast.import "Language"
      Yast.import "Wizard"
      Yast.import "Encoding"

      @func = Convert.to_string(WFM.Args(0))
      @param = Convert.to_map(WFM.Args(1))
      @ret = {}

      # Memorize current language to be able to detect a change.
      #
      @language_on_entry = Language.language
      Builtins.y2milestone("language_on_entry - 1: %1", @language_on_entry)

      if @func == "MakeProposal"
        @force_reset = Ops.get_boolean(@param, "force_reset", false)
        @language_changed = Ops.get_boolean(@param, "language_changed", false)

        Yast.import "Installation"
        Yast.import "Misc"
        Yast.import "Mode"

        if Mode.update &&
            (Language.languages == "" ||
              Language.languages == @language_on_entry) &&
            !@force_reset &&
            !Language.Modified
          Language.languages = Misc.CustomSysconfigRead(
            "INSTALLED_LANGUAGES",
            "",
            Ops.add(Installation.destdir, "/etc/sysconfig/language")
          )
          Builtins.y2milestone(
            "languages got from target system: %1",
            Language.languages
          )
        end

        # Make proposal and fill return map
        @prop = Language.MakeProposal(@force_reset, @language_changed)

        Builtins.y2milestone(
          "language_on_entry:%1 lang:%2, languages: %3",
          @language_on_entry,
          Language.language,
          Language.languages
        )

        if @force_reset && @language_on_entry != Language.language
          # Set it in YaST2
          Language.WfmSetLanguage
        end

        @ret = {
          "raw_proposal"     => @prop,
          "language_changed" => @language_on_entry != Language.language
        }
      elsif @func == "AskUser"
        Wizard.OpenAcceptDialog
        @args = {
          "enable_back" => true,
          "enable_next" => Ops.get_boolean(@param, "has_next", false)
        }
        @result = Convert.to_symbol(
          WFM.CallFunction("select_language", [@args])
        )

        Wizard.CloseDialog

        if @result == :back
          Builtins.y2milestone(
            "back to language_on_entry: %1",
            @language_on_entry
          )

          Language.Set(@language_on_entry)
        end

        # Fill return map

        @ret = {
          "workflow_sequence" => @result,
          "language_changed"  => @language_on_entry != Language.language
        }

        Builtins.y2debug(
          "Returning from proposal_language::AskUser() with: %1",
          @ret
        )
      elsif @func == "Description"
        # Fill return map.
        #
        # Static values do just nicely here, no need to call a function.

        @ret = {
          # label text
          "rich_text_title" => _("Language"),
          # menue label text
          "menu_title"      => _("&Language"),
          "id"              => "language_stuff"
        }
      end

      deep_copy(@ret)
    end
  end
end

Yast::LanguageProposalClient.new.main

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

# File:		country_simple_proposal.ycp
# Author:		Jiri Suchomel <jsuchome@suse.cz>
# Purpose:		Proposal for both language and keyboard layout settings.
#
# $Id$
module Yast
  class CountrySimpleProposalClient < Client
    def main
      textdomain "country"

      Yast.import "HTML"
      Yast.import "Keyboard"
      Yast.import "Language"

      @func = Convert.to_string(WFM.Args(0))
      @param = Convert.to_map(WFM.Args(1))
      @ret = {}

      if @func == "MakeProposal"
        @force_reset = Ops.get_boolean(@param, "force_reset", false)
        @language_changed = Ops.get_boolean(@param, "language_changed", false)
        # summary label <%1>-<%2> are HTML tags, leave untouched
        @kbd_proposal = Builtins.sformat(
          _("<%1>Keyboard Layout<%2>: %3"),
          "a href=\"country--keyboard\"",
          "/a",
          Keyboard.MakeProposal(@force_reset, @language_changed)
        )
        @proposal = Language.MakeProposal(@force_reset, @language_changed)
        # summary label <%1>-<%2> are HTML tags, leave untouched
        Ops.set(
          @proposal,
          0,
          Builtins.sformat(
            _("<%1>Language<%2>: %3"),
            "a href=\"country--language\"",
            "/a",
            Language.GetName
          )
        )

        @ret = {
          "preformatted_proposal" => HTML.List(
            Builtins.add(@proposal, @kbd_proposal)
          ),
          "language_changed"      => false,
          "links"                 => ["country--language", "country--keyboard"]
        }
      elsif @func == "Description"
        @ret = {
          # rich text label
          "rich_text_title" => _("Locale Settings"),
          "menu_titles"     => [
            # menu button label
            { "id" => "country--language", "title" => _("&Language") },
            # menu button label
            { "id" => "country--keyboard", "title" => _("&Keyboard Layout") }
          ],
          "id"              => "country"
        }
      elsif @func == "AskUser"
        @ret = if Ops.get_string(@param, "chosen_id", "") == "country--keyboard"
          Convert.to_map(
            WFM.CallFunction("keyboard_proposal", [@func, @param])
          )
        else
          Convert.to_map(
            WFM.CallFunction("language_proposal", [@func, @param])
          )
        end
      end
      deep_copy(@ret)
    end
  end
end

Yast::CountrySimpleProposalClient.new.main

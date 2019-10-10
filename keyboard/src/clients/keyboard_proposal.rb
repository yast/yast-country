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

# File:		keyboard_proposal.ycp
#
# $Id$
#
# Author:              Klaus Kaempf <kkaempf@suse.de>
#
# Purpose:		Proposal function dispatcher - keyboard.
#
#			See also file proposal-API.txt for details.
module Yast
  class KeyboardProposalClient < Client
    def main
      Yast.import "UI"
      textdomain "country"

      Yast.import "Arch"
      Yast.import "Keyboard"
      Yast.import "Wizard"

      Yast.include self, "keyboard/dialogs.rb"

      @func = Convert.to_string(WFM.Args(0))
      @param = Convert.to_map(WFM.Args(1))
      @ret = {}

      if @func == "MakeProposal"
        @force_reset = Ops.get_boolean(@param, "force_reset", false)
        @language_changed = Ops.get_boolean(@param, "language_changed", false)

        # call some function that makes a proposal here:
        #
        # DummyMod::MakeProposal( force_reset );

        # Fill return map

        @ret = {
          "raw_proposal"     => [
            Keyboard.MakeProposal(@force_reset, @language_changed)
          ],
          "language_changed" => false
        }
      elsif @func == "AskUser"
        if Arch.s390
          @ret = { "workflow_sequence" => :next, "language_changed" => false }
          return deep_copy(@ret)
        end

        Keyboard.Read # save the inital values

        @argmap = {
          "enable_back" => true,
          "enable_next" => Ops.get_boolean(@param, "has_next", false)
        }

        begin
          Yast::Wizard.OpenAcceptDialog
          @result = WFM.CallFunction("keyboard", [@argmap])
        ensure
          Yast::Wizard.CloseDialog
        end

        # Fill return map
        @ret = { "workflow_sequence" => @result, "language_changed" => false }
      elsif @func == "Description"
        # Fill return map.
        #
        # Static values do just nicely here, no need to call a function.

        @ret = {
          # summary item
          "rich_text_title" => _("Keyboard Layout"),
          # menue label text
          "menu_title"      => _("&Keyboard Layout"),
          "id"              => "keyboard_stuff"
        }
      end

      deep_copy(@ret)
    end
  end
end

Yast::KeyboardProposalClient.new.main

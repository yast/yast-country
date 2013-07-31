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

# File:	keyboard_simple_proposal.ycp
# Author:	Jiri Suchomel <jsuchome@suse.cz>
# Purpose:	Simple keyboard proposal (for overview tab)
# $Id$
module Yast
  class KeyboardSimpleProposalClient < Client
    def main
      textdomain "country"


      @func = Convert.to_string(WFM.Args(0))
      @param = Convert.to_map(WFM.Args(1))
      @ret = Convert.to_map(
        WFM.CallFunction("keyboard_proposal", [@func, @param])
      )
      deep_copy(@ret)
    end
  end
end

Yast::KeyboardSimpleProposalClient.new.main

# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2016 SUSE LINUX GmbH, Nuernberg, Germany.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------

require "yast"
require "cwm/widget"

Yast.import "Keyboard"

module Y2Country
  class KeyboardSelectionWidget < CWM::SelectionBox
    def initialize
      textdomain "country"
    end

    def label
      # widget label
      _("&Keyboard Layout")
    end

    def init
      if Yast::Keyboard.user_decision
        self.value = Yast::Keyboard.current_kbd
      else
        self.value = "english-us"
        Yast::Keyboard.Set(value)
      end
    end

    def handle
      Yast::Keyboard.Set(value)
    end

    def store
      handle
    end

    def items
      # a bit tricky as method return incompatible data
      Yast::Keyboard.GetKeyboardItems.map do |item|
        id, name, _enabled = item.params
        id = id.params.first
        [id, name]
      end
    end

    def help
      # help text for keyboard selection widget
      _(
        "<p>\n" \
          "Choose the <b>Keyboard layout</b> to be used during\n" \
          "installation and on the installed system.\n" \
          "</p>\n"
      )
    end
  end
end

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
Yast.import "Language"

module Y2Country
  module Widgets
    # Common parts for {KeyboardSelection} and {KeyboardSelectionCombo}.
    module KeyboardSelectionBase
      # param default [String] ID for default keyboard layout if not selected
      #   and no proposal for current language is found.
      #   Allowed values are defined in /usr/share/YaST2/data/keyboard_raw.ycp
      def initialize(default = "english-us")
        textdomain "country"
        @default = default
      end

      def label
        # widget label
        _("&Keyboard Layout")
      end

      # forces widget to report immediatelly after value changed.
      def opt
        [:notify]
      end

      def init
        if Yast::Keyboard.user_decision
          self.value = Yast::Keyboard.current_kbd
        else
          initial_value = Yast::Keyboard.GetKeyboardForLanguage(Yast::Language.language, @default)
          self.value = initial_value
          Yast::Keyboard.Set(value)
        end
      end

      def handle
        Yast::Keyboard.Set(value)
        # mark that user approve selection
        Yast::Keyboard.user_decision = true

        nil
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

    class KeyboardSelection < CWM::SelectionBox
      include KeyboardSelectionBase
    end

    class KeyboardSelectionCombo < CWM::ComboBox
      include KeyboardSelectionBase

      def opt
        [:notify, :hstretch]
      end
    end
  end
end

# ------------------------------------------------------------------------------
# Copyright (c) 2017 SUSE LINUX GmbH, Nuernberg, Germany.
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

Yast.import "Console"
Yast.import "Language"
Yast.import "Timezone"
Yast.import "UI"
Yast.import "Mode"

module Y2Country
  module Widgets
    # Language selection widget
    class LanguageSelection < CWM::ComboBox
      attr_reader :default

      # @param emit_event [Boolean] flag if handle of widget emit `:redraw` event
      #   when language changed or not
      def initialize(emit_event: false)
        super()

        textdomain "country"
        @default = Yast::Language.language
        @emit_event = emit_event
      end

      # Widget label
      #
      # @return [String]
      def label
        _("&Language")
      end

      # Widget options
      #
      # Widget is forced to report immediatelly after value changed.
      def opt
        [:notify, :hstretch]
      end

      # Initialize the selected value
      def init
        self.value = default
      end

      # Widget help text
      #
      # @return [String]
      def help
        _(
          "<p>\n" \
          "Choose the <b>Language</b> to be used during\n" \
          "installation and on the installed system.\n" \
          "</p>\n"
        )
      end

      # Handle value changes
      def handle
        return if value.nil? || value == default

        Yast::Timezone.ResetZonemap
        Yast::Language.Set(value)
        Yast::Language.languages = Yast::Language.RemoveSuffix(value)
        @default = value
        return nil if !@emit_event || Yast::Mode.config

        switch_language
        :redraw
      end

      # Store widget value
      def store
        handle

        switch_language if !@emit_event && !Yast::Mode.config

        nil
      end

      # Return the options to be shown in the combobox
      #
      # @return [Array<Array<String,String>>] Array of languages in form [code, description]
      def items
        @items ||= Yast::Language.GetLanguageItems(:first_screen).map do |item|
          id, description = item.to_a
          code = id.first
          [code, description]
        end
      end

    private

      def switch_language
        if Yast::Language.SwitchToEnglishIfNeeded(true)
          log.debug "UI switched to en_US"
        else
          Yast::Console.SelectFont(Yast::Language.language)
          # no yast translation for nn_NO, use nb_NO as a backup
          # FIXME: remove the hack, please
          if Yast::Language.language == "nn_NO"
            log.info "Nynorsk not translated, using Bokm\u00E5l"
            Yast::Language.WfmSetGivenLanguage("nb_NO")
          else
            Yast::Language.WfmSetLanguage
          end
        end
      end
    end
  end
end

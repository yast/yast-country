# ------------------------------------------------------------------------------
# Copyright (c) 2018 SUSE LINUX GmbH, Nuernberg, Germany.
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

Yast.import "Language"

module Y2Country
  module Widgets
    # Language selection widget
    #
    # In contrast to {Y2Country::Widgets::LanguageSelection}, this modules does not
    # modify the system language in any way.
    class SimpleLanguageSelection < CWM::ComboBox
      # @return [String] Default language code
      attr_reader :default
      # @return [String] List of languages to display (en_US, de_DE, etc.)
      attr_reader :languages

      # @param languages [Array<String>] List of languages to display (en_US, de_DE, etc.)
      # @param default   [String]        Default language code
      def initialize(languages, default)
        textdomain "y2packager"
        @languages = languages
        @default = default
        self.widget_id = "simple_language_selection"
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
        opts = [:notify]
        opts << :disabled unless items.size > 1
        opts
      end

      # [String] Default license language.
      DEFAULT_LICENSE_LANG = "en_US".freeze

      # Initialize to the given default language
      #
      # If the language is not in the list of options, it will try with the
      # short code (for instance, "de" for "de_DE"). If it fails again, it
      # initial value will be set to "en_US".
      def init
        languages = items.map(&:first)
        new_value =
          if languages.include?(default)
            default
          elsif default.include?("_")
            short_code = default.split("_").first
            languages.include?(short_code) ? short_code : nil
          end

        self.value = new_value || DEFAULT_LICENSE_LANG
      end

      # Widget help text
      #
      # @return [String]
      def help
        ""
      end

      # Return the options to be shown in the combobox
      #
      # @return [Array<Array<String,String>>] Array of languages in form [code, description]
      def items
        return @items if @items
        languages_map = Yast::Language.GetLanguagesMap(false)
        @items = languages.each_with_object([]) do |code, langs|
          attrs = languages_map.key?(code) ? languages_map[code] : nil
          lang, attrs = languages_map.find { |k, _v| k.start_with?(code) } if attrs.nil?

          if attrs.nil?
            log.warn "Not valid language '#{lang}'"
            next
          end

          log.debug "Using language '#{lang}' instead of '#{code}'" if lang =! code
          langs << [code, attrs[4]]
        end
        @items.sort_by! { |l| l[1] }
      end
    end
  end
end

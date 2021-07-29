# Copyright (c) [2019] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require "yast"
require "yast/i18n"

# Linux console keyboard layouts
class Keyboards
  extend Yast::I18n

  textdomain "country"

  # @return [Array<Hash{String => Object}>] keyboard descriptions
  #
  #   - description [String] translated name of layout
  #   - alias [String] yast-internal keybord id, to match the "keyboard" key
  #       in language/src/data/languages/language_*.ycp
  #   - code [String] keyboard name used by kbd, and
  #       present in /usr/share/systemd/kbd-model-map
  #       (test/data/keyboard_test.rb checks this)
  #   - suggested_for_lang [Array<String>] optional, language codes
  #       to suggest this layout for
  def self.all_keyboards
    [
      { "description" => _("English (US)"),
        "alias" => "english-us",
        "code" => "us",
        "suggested_for_lang" => ["ar_eg", "en", "nl_BE"]
      },
      { "description" => _("English (UK)"),
        "alias" => "english-uk",
        "code" => "uk"
      },
      { "description" => _("German"),
        "alias" => "german",
        "code" => "de-latin1-nodeadkeys",
        "suggested_for_lang" => ["de"]
      },
      { "description" => _("German (with deadkeys)"),
        "alias" => "german-deadkey",
        "code" => "de-latin1"
      },
      { "description" => _("German (Switzerland)"),
        "alias" => "german-ch",
        "code" => "sg-latin1",
        "suggested_for_lang" => ["de_CH"]
      },
      { "description" => _("French"),
        "alias" => "french",
        "code" => "fr-latin1",
        "suggested_for_lang" => ["br_FR", "fr", "fr_BE"]
      },
      { "description" => _("French (AFNOR)"),
        "alias" => "french-afnor",
        "code" => "fr-afnor",
        "suggested_for_lang" => ["br_FR", "fr", "fr_BE"]
      },
      { "description" => _("French (Switzerland)"),
        "alias" => "french-ch",
        "code" => "fr_CH-latin1",
        "suggested_for_lang" => ["fr_CH"]
      },
      { "description" => _("French (Canada)"),
        "alias" => "french-ca",
        "code" => "cf"
      },
      { "description" => _("Canadian (Multilingual)"),
        "alias" => "cn-latin1",
        "code" => "cn-latin1",
        "suggested_for_lang" => ["fr_CA"]
      },
      { "description" => _("Spanish"),
        "alias" => "spanish",
        "code" => "es",
        "suggested_for_lang" => ["es"]
      },
      { "description" => _("Spanish (Latin America)"),
        "alias" => "spanish-lat",
        "code" => "la-latin1"
      },
      { "description" => _("Spanish (CP 850)"),
        "alias" => "spanish-lat-cp850",
        "code" => "es-cp850"
      },
      { "description" => _("Spanish (Asturian variant)"),
        "alias" => "spanish-ast",
        "code" => "es-ast"
      },
      { "description" => _("Italian"),
        "alias" => "italian",
        "code" => "it",
        "suggested_for_lang" => ["it"]
      },
      { "description" => _("Persian"),
        "alias" => "persian",
        "code" => "ir",
        "suggested_for_lang" => ["fa_IR"]
      },
      { "description" => _("Portuguese"),
        "alias" => "portugese",
        "code" => "pt-latin1"
      },
      { "description" => _("Portuguese (Brazil)"),
        "alias" => "portugese-br",
        "code" => "br-abnt2"
      },
      { "description" => _("Portuguese (Brazil-- US accents)"),
        "alias" => "portugese-br-usa",
        "code" => "us-acentos"
      },
      { "description" => _("Greek"),
        "alias" => "greek",
        # Left-shift+Alt switches layouts
        # Windows (Super) is a Greek-shift
        "code" => "gr"
      },
      { "description" => _("Dutch"),
        "alias" => "dutch",
        "code" => "nl"
      },
      { "description" => _("Danish"),
        "alias" => "danish",
        "code" => "dk-latin1"
      },
      { "description" => _("Norwegian"),
        "alias" => "norwegian",
        "code" => "no-latin1",
        "suggested_for_lang" => ["no_NO", "nn_NO"]
      },
      { "description" => _("Swedish"),
        "alias" => "swedish",
        "code" => "sv-latin1"
      },
      { "description" => _("Finnish"),
        "alias" => "finnish",
        "code" => "fi"
      },
      { "description" => _("Czech"),
        "alias" => "czech",
        "code" => "cz-us-qwertz"
      },
      { "description" => _("Czech (qwerty)"),
        "alias" => "czech-qwerty",
        "code" => "cz-lat2-us"
      },
      { "description" => _("Slovak"),
        "alias" => "slovak",
        "code" => "sk-qwertz"
      },
      { "description" => _("Slovak (qwerty)"),
        "alias" => "slovak-qwerty",
        "code" => "sk-qwerty"
      },
      { "description" => _("Slovene"),
        "alias" => "slovene",
        "code" => "slovene"
      },
      { "description" => _("Hungarian"),
        "alias" => "hungarian",
        "code" => "hu"
      },
      { "description" => _("Polish"),
        "alias" => "polish",
        "code" => "Pl02"
      },
      { "description" => _("Russian"),
        "alias" => "russian",
        "code" => "ruwin_alt-UTF-8",
        "suggested_for_lang" => ["ru", "ru_RU.KOI8-R"]
      },
      { "description" => _("Serbian"),
        "alias" => "serbian",
        "code" => "sr-cy",
        "suggested_for_lang" => ["sr_YU"]
      },
      { "description" => _("Estonian"),
        "alias" => "estonian",
        "code" => "et"
      },
      { "description" => _("Lithuanian"),
        "alias" => "lithuanian",
        "code" => "lt.baltic"
      },
      { "description" => _("Turkish"),
        "alias" => "turkish",
        "code" => "trq"
      },
      { "description" => _("Croatian"),
        "alias" => "croatian",
        "code" => "croat"
      },
      { "description" => _("Japanese"),
        "alias" => "japanese",
        "code" => "jp106"
      },
      { "description" => _("Belgian"),
        "alias" => "belgian",
        "code" => "be-latin1",
        "suggested_for_lang" => ["be_BY"]
      },
      { "description" => _("Dvorak"),
        "alias" => "dvorak",
        # Beware, Dvorak is completely different from QWERTY;
        # see also https://en.wikipedia.org/wiki/Dvorak_keyboard_layout
        "code" => "dvorak"
      },
      { "description" => _("Icelandic"),
        "alias" => "icelandic",
        "code" => "is-latin1",
        "suggested_for_lang" => ["is_IS"]
      },
      { "description" => _("Ukrainian"),
        "alias" => "ukrainian",
        # AltGr or Right-Ctrl switch layouts
        "code" => "ua-utf"
      },
      { "description" => _("Khmer"),
        "alias" => "khmer",
        "code" => "khmer"
      },
      { "description" => _("Korean"),
        "alias" => "korean",
        "code" => "korean"
      },
      { "description" => _("Arabic"),
        "alias" => "arabic",
        "code" => "arabic"
      },
      { "description" => _("Tajik"),
        "alias" => "tajik",
        # AltGr switches layouts
        "code" => "tj_alt-UTF8"
      },
      { "description" => _("Traditional Chinese"),
        "alias" => "taiwanese",
        "code" => "tw"
      },
      { "description" => _("Simplified Chinese"),
        "alias" => "chinese",
        "code" => "cn"
      },
      { "description" => _("Romanian"),
        "alias" => "romanian",
        "code" => "ro"
      },
      { "description" => _("US International"),
        "alias" => "us-int",
        "code" => "us-acentos"
      }
    ]
  end

  # Evaluate the proposed keyboard for a given language
  #
  # @param [String] language e.g. "de_CH"
  #
  # @return [String] keyboard alias e.g. "german-ch" or nil
  #
  def self.suggested_keyboard(language)
    keyboard = all_keyboards.detect do |kb|
      kb["suggested_for_lang"] &&
      kb["suggested_for_lang"].include?(language)
    end
    keyboard ? keyboard["alias"] : nil
  end

  # Evaluate alias name for a given keymap
  #
  # @param [String] keymap e.g. "de-latin1-nodeadkeys"
  #
  # @return [String] keyboard alias e.g. "german" or nil
  #
  def self.alias(keymap)
    keyboard = all_keyboards.detect {|kb| kb["code"] == keymap }
    keyboard ? keyboard["alias"] : nil
  end

  # Evaluate description for an given alias name
  #
  # @param [String] alias e.g. "english-us"
  #
  # @return [String] translated description or nil
  #
  def self.description(key_alias)
    keyboard = all_keyboards.detect {|kb| kb["alias"] == key_alias }
    keyboard ? keyboard["description"] : nil
  end

  # Evaluate kemap for an given alias name
  #
  # @param [String] alias e.g. "english-us"
  #
  # @return [String] keymap (e.g. "de_DE") or nil
  #
  def self.code(key_alias)
    keyboard = all_keyboards.detect {|kb| kb["alias"] == key_alias }
    keyboard ? keyboard["code"] : nil
  end
end

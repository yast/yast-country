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
  #   - legacy_code [String] old keyboard name used by kbd-legacy,
  #       present here so it can be automatically replaced if found
  #       in existing configurations (upgrade and AutoYaST profiles);
  #       see also legacy_replacement()
  #   - suggested_for_lang [Array<String>] optional, language codes
  #       to suggest this layout for
  def self.all_keyboards
    always_present_keyboards + optional_keyboards
  end

  # @see all_keyboards
  def self.always_present_keyboards
    # Now (2021-12-07) using keymaps from the new kbd package
    # from /usr/share/kbd/keymaps/xkb, no longer kbd-legacy
    # from /usr/share/kbd/keymaps/{amiga,atari,i386,include,mac,sun}
    #
    # "not_in_xkb": the xkb layout has no Latin letters and is therefore
    # excluded from the console conversion. Dropping kbd-legacy would break
    # these languages.
    #
    # "us_symlink": it has always been just a symlink to the us layout.
    # bsc#1194609 moves the symlinks to kbd.rpm
    #
    # See also  man xkeyboard-config
    [
      { "description" => _("English (US)"),
        "alias" => "english-us",
        "code" => "us",
        # No different legacy_code
        "suggested_for_lang" => ["ar_eg", "en", "nl_BE"]
      },
      { "description" => _("English (UK)"),
        "alias" => "english-uk",
        "code" => "gb",
        "legacy_code" => "uk"
      },
      { "description" => _("German"),
        "alias" => "german",
        "code" => "de-nodeadkeys",
        "legacy_code" => "de-latin1-nodeadkeys",
        "suggested_for_lang" => ["de"]
      },
      { "description" => _("German (with deadkeys)"),
        "alias" => "german-deadkey",
        "code" => "de",
        "legacy_code" => "de-latin1"
      },
      { "description" => _("German (Switzerland)"),
        "alias" => "german-ch",
        "code" => "ch",
        "legacy_code" => "sg-latin1",
        "suggested_for_lang" => ["de_CH"]
      },
      { "description" => _("French"),
        "alias" => "french",
        "code" => "fr",
        "legacy_code" => "fr-latin1",
        "suggested_for_lang" => ["br_FR", "fr", "fr_BE"]
      },
      { "description" => _("French (Switzerland)"),
        "alias" => "french-ch",
        "code" => "ch-fr",
        "legacy_code" => "fr_CH-latin1",
        "suggested_for_lang" => ["fr_CH"]
      },
      { "description" => _("French (Canada)"),
        "alias" => "french-ca",
        "code" => "ca", # Not ca-fr-legacy (bsc#1196891)
        "legacy_code" => "cf"
      },
      {
        # CSA should probably not be translated;
        # it stands for Canadian Standards Association
        # https://en.wikipedia.org/wiki/CSA_keyboard
        "description" => _("Canadian (CSA)"),
        "alias" => "cn-latin1",
        "code" => "ca-multix",
        "legacy_code" => "cn-latin1",
        "suggested_for_lang" => ["fr_CA"]
      },
      { "description" => _("Spanish"),
        "alias" => "spanish",
        "code" => "es",
        # No different legacy_code
        "suggested_for_lang" => ["es"]
      },
      { "description" => _("Spanish (Latin America)"),
        "alias" => "spanish-lat",
        "code" => "latam",
        "legacy_code" => "la-latin1"
      },
      { "description" => _("Spanish (Asturian variant)"),
        "alias" => "spanish-ast",
        "code" => "es-ast"
        # No different legacy_code
      },
      { "description" => _("Italian"),
        "alias" => "italian",
        "code" => "it",
        # No different legacy_code
        "suggested_for_lang" => ["it"]
      },
      { "description" => _("Persian"),
        "alias" => "persian",
        "code" => "ir", # us_symlink
        "suggested_for_lang" => ["fa_IR"]
      },
      { "description" => _("Portuguese"),
        "alias" => "portugese",
        "code" => "pt",
        "legacy_code" => "pt-latin1"
      },
      { "description" => _("Portuguese (Brazil)"),
        "alias" => "portugese-br",
        "code" => "br",
        "legacy_code" => "br-abnt2"
      },
      { "description" => _("Portuguese (Brazil -- US accents)"),
        "alias" => "portugese-br-usa",
        "code" => "br-nativo-us",
        "legacy_code" => "us-acentos"
      },
      { "description" => _("Greek"),
        "alias" => "greek",
        # Left-shift+Alt switches layouts
        # Windows (Super) is a Greek-shift
        "code" => "gr"  # not_in_xkb
        # No different legacy_code
      },
      { "description" => _("Dutch"),
        "alias" => "dutch",
        "code" => "nl"
        # No different legacy_code
      },
      { "description" => _("Danish"),
        "alias" => "danish",
        "code" => "dk",
        "legacy_code" => "dk-latin1"
      },
      { "description" => _("Norwegian"),
        "alias" => "norwegian",
        "code" => "no",
        "legacy_code" => "no-latin1",
        "suggested_for_lang" => ["no_NO", "nn_NO"]
      },
      { "description" => _("Swedish"),
        "alias" => "swedish",
        "code" => "se",
        "legacy_code" => "sv-latin1"
      },
      { "description" => _("Finnish"),
        "alias" => "finnish",
        "code" => "fi-kotoistus",
        "legacy_code" => "fi"
      },
      { "description" => _("Czech"),
        "alias" => "czech",
        "code" => "cz",
        "legacy_code" => "cz-us-qwertz"
      },
      { "description" => _("Czech (qwerty)"),
        "alias" => "czech-qwerty",
        "code" => "cz-qwerty",
        "legacy_code" => "cz-lat2-us"
      },
      { "description" => _("Slovak"),
        "alias" => "slovak",
        "code" => "sk",
        "legacy_code" => "sk-qwertz"
      },
      { "description" => _("Slovak (qwerty)"),
        "alias" => "slovak-qwerty",
        "code" => "sk-qwerty"
        # No different legacy_code
      },
      { "description" => _("Slovene"),
        "alias" => "slovene",
        "code" => "si",
        "legacy_code" => "slovene"
      },
      { "description" => _("Hungarian"),
        "alias" => "hungarian",
        "code" => "hu"
        # No different legacy_code
      },
      { "description" => _("Polish"),
        "alias" => "polish",
        "code" => "pl",
        "legacy_code" => "Pl02"
      },
      { "description" => _("Russian"),
        "alias" => "russian",
        "code" => "ruwin_alt-UTF-8", # not_in_xkb
        "suggested_for_lang" => ["ru", "ru_RU.KOI8-R"]
      },
      { "description" => _("Serbian"),
        "alias" => "serbian",
        # this is almost a case of not_in_xkb: sr-cy has a primary Latin
        # layout and a secondary Cyrillic one. Fortunately, unlike the other
        # Cyrillic languages, there is xkb/rs-latin
        "code" => "rs-latin",
        "legacy_code" => "sr-cy",
        "suggested_for_lang" => ["sr_YU"]
      },
      { "description" => _("Estonian"),
        "alias" => "estonian",
        "code" => "ee",
        "legacy_code" => "et"
      },
      { "description" => _("Lithuanian"),
        "alias" => "lithuanian",
        "code" => "lt",
        "legacy_code" => "lt.baltic"
      },
      { "description" => _("Turkish"),
        "alias" => "turkish",
        "code" => "tr",
        "legacy_code" => "trq"
      },
      { "description" => _("Croatian"),
        "alias" => "croatian",
        "code" => "hr",
        "legacy_code" => "croat"
      },
      { "description" => _("Japanese"),
        "alias" => "japanese",
        "code" => "jp",
        "legacy_code" => "jp106"
      },
      { "description" => _("Belgian"),
        "alias" => "belgian",
        "code" => "be",
        "legacy_code" => "be-latin1",
        "suggested_for_lang" => ["be_BY"]
      },
      { "description" => _("Dvorak"),
        "alias" => "dvorak",
        # Beware, Dvorak is completely different from QWERTY;
        # see also https://en.wikipedia.org/wiki/Dvorak_keyboard_layout
        "code" => "us-dvorak",
        "legacy_code" => "dvorak"
      },
      { "description" => _("Dvorak (programmer)"),
        "alias" => "dvp",
        # Beware, Dvorak is completely different from QWERTY;
        # see also https://en.wikipedia.org/wiki/Dvorak_keyboard_layout
        "code" => "us-dvp"
      },
      { "description" => _("Icelandic"),
        "alias" => "icelandic",
        "code" => "is",
        "legacy_code" => "is-latin1",
        "suggested_for_lang" => ["is_IS"]
      },
      { "description" => _("Ukrainian"),
        "alias" => "ukrainian",
        # AltGr or Right-Ctrl switch layouts
        "code" => "ua-utf" # not_in_xkb
      },
      { "description" => _("Khmer"),
        "alias" => "khmer",
        "code" => "khmer" # us_symlink
      },
      { "description" => _("Korean"),
        "alias" => "korean",
        "code" => "kr", # xkb/kr includes a us layout
        "legacy_code" => "korean"
      },
      { "description" => _("Arabic"),
        "alias" => "arabic",
        "code" => "arabic" # us_symlink
      },
      { "description" => _("Tajik"),
        "alias" => "tajik",
        # AltGr switches layouts
        "code" => "tj_alt-UTF8" # not_in_xkb
      },
      { "description" => _("Traditional Chinese"),
        "alias" => "taiwanese",
        "code" => "tw" # us-based
        # No different legacy_code
      },
      { "description" => _("Simplified Chinese"),
        "alias" => "chinese",
        "code" => "cn" # us-based
        # No different legacy_code
      },
      { "description" => _("Romanian"),
        "alias" => "romanian",
        "code" => "ro"
        # No different legacy_code
      },
      { "description" => _("US International"),
        "alias" => "us-int",
        "code" => "us-intl",
        "legacy_code" => "us-acentos"
      }
    ]
  end

  # Some keyboards are present in new openSUSE releases but not in older SLE
  # @see all_keyboards
  def self.optional_keyboards
    # memoize this
    return @optional_keyboards unless @optional_keyboards.nil?

    @optional_keyboards = []

    # The afnor layout was added to xkeyboard-config in 2019-06
    # but SLE15-SP4 only has 2.23 released in 2018
    afnor_test = lambda do
      kmm = File.read("/usr/share/systemd/kbd-model-map") rescue ""
      kmm.match?("^fr-afnor")
    end
    afnor = {
      "description" => _("French (AFNOR)"),
      "alias" => "french-afnor",
      "code" => "fr-afnor",
      # No different legacy_code
      "suggested_for_lang" => ["br_FR", "fr", "fr_BE"]
    }
    @optional_keyboards.push(afnor) if afnor_test.call

    @optional_keyboards
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

  # Evaluate keymap for an given alias name
  #
  # @param [String] alias e.g. "english-us"
  #
  # @return [String] keymap (e.g. "de_DE") or nil
  #
  def self.code(key_alias)
    keyboard = all_keyboards.detect {|kb| kb["alias"] == key_alias }
    keyboard ? keyboard["code"] : nil
  end

  # Check if a keymap code is a legacy code.
  #
  # @param [String] code, e.g. "de-latin1"
  #
  # @return true if it is in "legacy_code" of any keymap hash, false if not
  #
  def self.legacy_code?(code)
    return false if code.nil?

    all_keyboards.any?{ |kb| kb["legacy_code"] == code }
  end

  # Return the new keymap code for a legacy code.
  #
  # @param [String] code, e.g. "de-latin1"
  #
  # @return [String] replacement, e.g. "de", or the original if not found.
  #
  def self.legacy_replacement(legacy_code)
    keyboard = all_keyboards.detect { |kb| kb["legacy_code"] == legacy_code }
    keyboard ? keyboard["code"] : legacy_code
  end
end

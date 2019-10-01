class Keyboards
  @@keyboards = [
    { description: _("English (US)"),
      alias: "english-us",
      code: "us",
      suggested_for_lang: ["ar_eg", "en", "nl_BE"]
    },
    { description: _("English (UK)"),
      alias: "english-uk",
      code: "uk"
    },
    { description: _("German"),
      alias: "german-deadkey",
      code: "de-latin1-nodeadkeys"
    },
    { description: _("German (with deadkeys)"),
      alias: "german",
      code: "de-latin1",
      suggested_for_lang: ["de"]
    },
    { description: _("German (Switzerland)"),
      alias: "german-ch",
      code: "sg-latin1",
      suggested_for_lang: ["de_CH"]
    },
    { description: _("French"),
      alias: "french",
      code: "fr-latin1",
      suggested_for_lang: ["br_FR", "fr", "fr_BE"]
    },
    { description: _("French (Switzerland)"),
      alias: "french-ch",
      code: "fr_CH-latin1",
      suggested_for_lang: ["fr_CH"]
    },
    { description: _("French (Canada)"),
      alias: "french-ca",
      code: "cf"
    },
    { description: _("Canadian (Multilingual)"),
      alias: "cn-latin1",
      code: "cn-latin1",
      suggested_for_lang: ["fr_CA"]
    },
    { description: _("Spanish"),
      alias: "spanish",
      code: "es",
      suggested_for_lang: ["es"]
    },
    { description: _("Spanish (Latin America)"),
      alias: "spanish-lat",
      code: "la-latin1"
    },
    { description: _("Spanish (CP 850)"),
      alias: "spanish-lat-cp850",
      code: "es-cp850"
    },
    { description: _("Spanish (Asturian variant)"),
      alias: "spanish-ast",
      code: "es-ast"
    },
    { description: _("Italian"),
      alias: "italian",
      code: "it",
      suggested_for_lang: ["it"]
    },
    { description: _("Persian"),
      alias: "persian",
      code: "ir",
      suggested_for_lang: ["fa_IR"]
    },
    { description: _("Portuguese"),
      alias: "portugese",
      code: "pt-latin1"
    },
    { description: _("Portuguese (Brazil)"),
      alias: "portugese-br",
      code: "br-abnt2"
    },
    { description: _("Portuguese (Brazil-- US accents)"),
      alias: "portugese-br-usa",
      code: "us-acentos"
    },
    { description: _("Greek"),
      alias: "greek",
      code: "gr"
    },
    { description: _("Dutch"),
      alias: "dutch",
      code: "nl"
    },
    { description: _("Danish"),
      alias: "danish",
      code: "dk-latin1"
    },
    { description: _("Norwegian"),
      alias: "norwegian",
      code: "no-latin1",
      suggested_for_lang: ["no_NO", "nn_NO"]
    },
    { description: _("Swedish"),
      alias: "swedish",
      code: "sv-latin1"
    },
    { description: _("Finnish"),
      alias: "finnish",
      code: "fi"
    },
    { description: _("Czech"),
      alias: "czech",
      code: "cz-us-qwertz"
    },
    { description: _("Czech (qwerty)"),
      alias: "czech-qwerty",
      code: "cz-lat2-us"
    },
    { description: _("Slovak"),
      alias: "slovak",
      code: "sk-qwertz"
    },
    { description: _("Slovak (qwerty)"),
      alias: "slovak-qwerty",
      code: "sk-qwerty"
    },
    { description: _("Slovene"),
      alias: "slovene",
      code: "slovene"
    },
    { description: _("Hungarian"),
      alias: "hungarian",
      code: "hu"
    },
    { description: _("Polish"),
      alias: "polish",
      code: "Pl02"
    },
    { description: _("Russian"),
      alias: "russian",
      code: "ruwin_alt-UTF-8",
      suggested_for_lang: ["ru", "ru_RU.KOI8-R"]
    },
    { description: _("Serbian"),
      alias: "serbian",
      code: "sr-cy",
      suggested_for_lang: ["sr_YU"]
    },
    { description: _("Estonian"),
      alias: "estonian",
      code: "et"
    },
    { description: _("Lithuanian"),
      alias: "lithuanian",
      code: "lt.baltic"
    },
    { description: _("Turkish"),
      alias: "turkish",
      code: "trq"
    },
    { description: _("Croatian"),
      alias: "croatian",
      code: "croat"
    },
    { description: _("Japanese"),
      alias: "japanese",
      code: "jp106"
    },
    { description: _("Belgian"),
      alias: "belgian",
      code: "be-latin1",
      suggested_for_lang: ["be_BY"]
    },
    { description: _("Dvorak"),
      alias: "dvorak",
      code: "dvorak"
    },
    { description: _("Icelandic"),
      alias: "icelandic",
      code: "is-latin1",
      suggested_for_lang: ["is_IS"]
    },
    { description: _("Ukrainian"),
      alias: "ukrainian",
      code: "ua"
    },
    { description: _("Khmer"),
      alias: "khmer",
      code: "khmer"
    },
    { description: _("Korean"),
      alias: ""korean,
      code: "korean"
    },
    { description: _("Arabic"),
      alias: "arabic",
      code: "arabic"
    },
    { description: _("Tajik"),
      alias: "tajik",
      code: "tj_alt-UTF8"
    },
    { description: _("Traditional Chinese"),
      alias: "taiwanese",
      code: "taiwanese"
    },
    { description: _("Simplified Chinese"),
      alias: "chinese",
      code: "chinese"
    },
    { description: _("Romanian"),
      alias: "romanian",
      code: "ro"
    },
    { description: _("US International"),
      alias: "us-int",
      code: "us-acentos"
    }
  ]

  def self.all_keyboards
    @@keyboards
  end

  def self.suggested_keyboard(language)
  end
end

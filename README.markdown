# YaST - The Basic Libraries #

[![Workflow Status](https://github.com/yast/yast-country/workflows/CI/badge.svg?branch=master)](
https://github.com/yast/yast-country/actions?query=branch%3Amaster)
[![OBS](https://github.com/yast/yast-country/actions/workflows/submit.yml/badge.svg)](https://github.com/yast/yast-country/actions/workflows/submit.yml)
[![Coverage Status](https://coveralls.io/repos/yast/yast-country/badge.svg)](https://coveralls.io/r/yast/yast-country)

Country specific data and configuration modules (language, keyboard,
timezone) for YaST2.

## Installation ##

    make -f Makefile.cvs
    make
    sudo make install

## Running Testsuites ##

    make check

## Links ##

  * See more at http://en.opensuse.org/openSUSE:YaST_development

## Adding a New Country

- console/src/data/consolefonts.json

    - key: locale_id
    - font: /usr/share/kbd/consolefonts/%s.gz (kbd.rpm)
    - unicodeMap: ?
    - screenMap: ?
    - magic: ?

    ---

    ```json
    "en_GB": {
        "font": "eurlatgr.psfu",
        "unicodeMap": "",
        "screenMap": "",
        "magic": ""
    }
    ```

    ---

- keyboard/src/data/keyboards.rb

    Array of keyboard layout

    - description: translatable string
    - alias: yast keyboard id
    - code: keymap
    - suggested_for_lang: Languages which fits to this keyboard layout.

    ---

    ```js
    [
      { "description" => _("English (US)"),
        "alias" => "english-us",
        "code" => "us",
        "suggested_for_lang" => ["ar_eg", "en", "nl_BE"]
      },
      ...
    ]
    ```

    ---

- language/src/data/languages/language_%s.ycp (ll_TT)
    - ll_TT: 5-tuple
        - (native) name in unicode
        - (native) name in ascii
        - utf-8 modifier
        - non-utf-8 modifier
        - translatable name
    - timezone: tz_id
    - keyboard: yast_keyboard_id

    ---

    ```js
    $[
        "en_GB"	: [
            "English (UK)",
            "English (UK)",
            ".UTF-8",
            "",
            _("English (UK)")
        ],
        "timezone"	: "Europe/London",
        "keyboard"	: "english-uk",
    ]
    ```

    ---

- timezone/src/data/lang2tz.ycp

    > NOTE: it is also in language_xx_XX.ycp

    - key: locale_id
    - value: tz_id

    ---

    ```js
    "en_GB": "Europe/London"
    ```

    ---

- timezone/src/data/timezone_raw.ycp

    Translatable TZ names (timezone_db.pot)


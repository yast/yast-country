# YaST - The Basic Libraries #

[![Travis Build](https://travis-ci.org/yast/yast-country.svg?branch=master)](https://travis-ci.org/yast/yast-country)
[![Jenkins Build](http://img.shields.io/jenkins/s/https/ci.opensuse.org/yast-country-master.svg)](https://ci.opensuse.org/view/Yast/job/yast-country-master/)
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

- keyboard/src/data/keyboard_raw.ycp

    Console keyboard layout

    - key: yast_keyboard_id
    - value: pair of translatable_string, more_data:
        - key: keyboard_hardware (pc104, macintosh, type4, type5, type5_euro)
        - value: more_data:
            - ncurses: /usr/share/kbd/keymaps/xkb/%s
            - compose: ? (optional)

    ---

    ```js
    "english-uk": [
        _("English (UK)"),
        $[
            "pc104":      $[ "ncurses": "gb.map.gz"],
            "macintosh":  $[ "ncurses": "gb-mac.map.gz" ],
            "type4":      $[ "ncurses": "us.map.gz"],
            "type5":      $[ "ncurses": "us.map.gz"],
            "type5_euro": $[ "ncurses": "us.map.gz"],
        ]
    ]

    ```

    ---

- keyboard/src/data/lang2keyboard.ycp (TODO convert)
    - key: locale_id
    - value: yast_keyboard_id

    ---

    ```js
    "en_GB": "english-uk"
    ```

    ---

- keyboard/src/data/xkblayout2keyboard.ycp (TODO convert)

    man xkeyboard-config

    - key: xkblayout_id ?
    - value: yast_keyboard_id

    ---

    ```js
    "gb": "english-uk"
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


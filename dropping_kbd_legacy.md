Dropping kbd-legacy.rpm
=======================


kbd.rpm is a package including keyboard maps for the text console (not the
graphical envirnoment like X or Wayland)

Since 2015 these console keyboard maps have been generated from the X keyboard
maps packaged in xkeyboard-config.rpm. We have also included the original
console maps in the kbd-legacy subpackage.

Since January 2022 (SLE15-SP4)  we have switched the console keymaps from the
legacy ones to the ones generated from xkb.

| Dropped keyboard map | Selected replacement | Other options | Note                    |
| -------------------- | -------------------- | ------------- | ---------               |
| be-latin1            | be                   |               |                         |
| br-abnt2             | br                   | br-nativo     |                         |
| cf                   | ca-fr-legacy         |               |                         |
| cn-latin1            | ca-multi             |               |                         |
| croat                | hr                   |               |                         |
| cz-lat2-us           | cz-qwerty            |               |                         |
| cz-us-qwertz         | cz                   |               |                         |
| de-latin1            | de                   |               |                         |
| de-latin1-nodeadkeys | de-nodeadkeys        |               |                         |
| dk-latin1            | dk                   |               |                         |
| dvorak               | us-dvorak            |               |                         |
| es-cp850             | -- (DROPPED)         |               | Covered by `es` well enough |
| et                   | ee                   |               |                         |
| fi                   | fi-kotoistus         |               |                         |
| fr-latin1            | fr                   |               |                         |
| fr_CH-latin1         | ch-fr                |               |                         |
| hu                   | hu                   | hu-standard   |                         |
| is-latin1            | is                   |               |                         |
| jp106                | jp                   |               |                         |
| la-latin1            | latam                |               |                         |
| lt.baltic            | lt                   |               |                         |
| nl                   | nl                   | nl-std        |                         |
| no-latin1            | no                   |               |                         |
| Pl02                 | pl                   |               |                         |
| pt-latin1            | pt                   |               |                         |
| sg-latin1            | ch                   |               |                         |
| sk-qwerty            | sk-qwerty            |               |                         |
| sk-qwertz            | sk                   |               |                         |
| slovene              | si                   |               |                         |
| sr-cy                | rs-latin             |               | Serbian, Latin only     |
| sv-latin1            | se                   |               |                         |
| trq                  | tr                   |               |                         |
| uk                   | gb                   |               |                         |
| us-acentos           | br-nativo-us         |               | Brazilian               |
| us-acentos           | us-intl              |               | US International        |


## Legacy being better

Some languages have a need to switch between their native non-Latin script and
the Latin script, and have legacy keymaps which combine these two scripts in a
single keymap.

At the same time, their xkb layout contains no Latin letters, relying on being
able to switch to another Latin layout. Their xkb layouts are not converted
for console.

We're using `localectl set-keymap` to set both the console and X11 keymaps at
once, so removing kbd-legacy would break these languages als in X11.

| Legacy keyboard map  | Selected replacement | Other options | Note           |
| -------------------- | -------------------- | ------------- | ---------      |
| gr                   | ?                    |               | Greek          |
| ruwin_alt-UTF-8      | ?                    |               | Russian        |
| tj_alt-UTF8          | ?                    |               | Tajik          |
| ua-utf               | ?                    |               | Ukrainian      |

## Fallback to the US layout

Some languages have never had a native console layout. Their console keymaps
are simply a symlink to the `us` keymap:

- arabic
- ir (Iran, Persian/Farsi)
- khmer

These layouts are moving from kbd-legacy.rpm to kbd.rpm;
[bsc#1194609](https://bugzilla.suse.com/show_bug.cgi?id=1194609).

Dropping kbd-legacy.rpm
=======================


kbd.rpm is a package including keyboard maps for the text console (not the
graphical envirnoment like X or Wayland)

since 2015 these console keyboard maps have been generated from the X keyboard
maps pckaged in xkeyboard-config.rpm. We have also included the original
console maps in the kbd-legacy subpackage

until 2021 (openSUSE XX.X, SLE XX SP X)
we included a kbd-legacy subpackage, but $reasons ...


| Dropped keyboard map | Selected replacement | Other options | Note                    |
| -------------------- | -------------------- | ------------- | ---------               |
| uk                   | gb                   |               |                         |
| de-latin1-nodeadkeys | de-nodeadkeys        |               |                         |
| de-latin1            | de                   |               |                         |
| sg-latin1            | ch                   |               |                         |
| fr-latin1            | fr                   |               |                         |
| fr_CH-latin1         | ch-fr                |               |                         |
| cf                   | ca-fr-legacy         |               |                         |
| cn-latin1            | ca-multi             |               |                         |
| la-latin1            | latam                |               |                         |
| es-cp850             | -- (DROPPED)         |               | DROPPED                 |
| pt-latin1            | pt                   |               |                         |
| br-abnt2             | br                   | br-nativo     |                         |
| us-acentos           | br-nativo-us         |               |                         |
| nl                   | nl                   | nl-std        |                         |
| dk-latin1            | dk                   |               |                         |
| no-latin1            | no                   |               |                         |
| sv-latin1            | se                   |               |                         |
| fi                   | fi-classic           |               | no xkb/fi, unsure       |
| cz-us-qwertz         | cz                   |               |                         |
| cz-lat2-us           | cz-lat2-us           |               | (qwerty, check)         |
| sk-qwertz            | sk                   |               |                         |
| sk-qwerty            | sk-qwerty            |               |                         |
| slovene              | si                   |               |                         |
| hu                   | hu                   | hu-standard   |                         |
| Pl02                 | pl                   |               |                         |
| ruwin_alt-UTF-8      | ru-cv_latin          |               | noxkb/ru, check         |
| sr-cy                | ba                   | rs-latin      | was symlink to sr-latin |
| et                   | ee                   |               |                         |
| lt.baltic            | lt                   |               |                         |
| trq                  | tr                   |               |                         |
| croat                | hr                   |               |                         |
| jp106                | jp                   |               |                         |
| be-latin1            | be                   |               |                         |
| dvorak               | us-dvorak            |               |                         |
| is-latin1            | is                   |               |                         |
| ua-utf               | ua-utf               |               | no ua*                  |
| cn                   | cm                   |               | cn symlink              |
| us-acentos           | us-intl              |               |                         |



## Missing at This Time

Right now, there are a number of keyboard maps that are not (yet) available in
the new _kbd_ package (i.e. below `/usr/share/kbd/xkb`):


| Missing keyboard map | Selected replacement | Other options | Note                    |
| -------------------- | -------------------- | ------------- | ---------               |
| ir                   |                      |               | was symlink to 'us'     |
| gr                   |                      |               | none found              |
| ua-utf               |                      |               | none found              |
| khmer                |                      |               | none found              |
| arabic               |                      |               | none found              |
| tj_alt-UTF8          |                      |               | none found              |


Those keyboard maps are still there in the list, but trying to use them will
fail if the _kbd-legacy_ package is not available. The plan is that it will not
be installed by default (and no longer be in the inst-sys) anymore.

But on the installed system, a user will still be able to install it and start
`yast keyboard` again to use those keyboard maps.

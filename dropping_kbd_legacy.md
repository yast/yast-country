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
| es-cp850             | -- (DROPPED)         |               | DROPPED                 |
| et                   | ee                   |               |                         |
| fi                   | fi-classic           |               | no xkb/fi, unsure       |
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
| ruwin_alt-UTF-8      | ru-cv_latin          |               | nox kb/ru, check        |
| sg-latin1            | ch                   |               |                         |
| sk-qwerty            | sk-qwerty            |               |                         |
| sk-qwertz            | sk                   |               |                         |
| slovene              | si                   |               |                         |
| sr-cy                | ba                   | rs-latin      | was symlink to sr-latin |
| sv-latin1            | se                   |               |                         |
| trq                  | tr                   |               |                         |
| uk                   | gb                   |               |                         |
| us-acentos           | br-nativo-us         |               |                         |
| us-acentos           | us-intl              |               |                         |



## Missing at This Time

Right now, there are a number of keyboard maps that are not (yet) available in
the new _kbd_ package (i.e. below `/usr/share/kbd/xkb`):


| Missing keyboard map | Selected replacement | Other options | Note                    |
| -------------------- | -------------------- | ------------- | ---------               |
| arabic               |                      |               | none found              |
| gr                   |                      |               | none found              |
| ir                   |                      |               | was symlink to 'us'     |
| khmer                |                      |               | none found              |
| tj_alt-UTF8          |                      |               | none found              |
| ua-utf               |                      |               | none found              |


Those keyboard maps are still there in the list, but trying to use them will
fail if the _kbd-legacy_ package is not available. The plan is that it will not
be installed by default (and no longer be in the inst-sys) anymore.

But on the installed system, a user will still be able to install it and start
`yast keyboard` again to use those keyboard maps.

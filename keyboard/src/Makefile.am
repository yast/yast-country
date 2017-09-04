# Sources for country

module_DATA = \
  modules/Keyboard.rb

client_DATA = \
  clients/keyboard_auto.rb \
  clients/keyboard_proposal.rb \
  clients/keyboard_simple_proposal.rb \
  clients/keyboard.rb

yncludedir = @yncludedir@/keyboard
ynclude_DATA = \
  include/keyboard/dialogs.rb

scrconf_DATA = \
  scrconf/sysconfig_keyboard.scr \
  scrconf/etc_vconsole_conf.scr

schemafilesdir = $(schemadir)/autoyast/rnc
schemafiles_DATA = \
  autoyast-rnc/keyboard.rnc

ydata_DATA = \
  data/keyboard_raw.ycp \
  data/keyboard_raw_opensuse.ycp \
  data/xkblayout2keyboard.ycp \
  data/lang2keyboard.ycp

desktop_DATA = \
  desktop/keyboard.desktop

ywidgetsdir = @ylibdir@/y2country/widgets
ywidgets_DATA = \
  lib/y2country/widgets/keyboard_selection.rb

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(scrconf_DATA) \
  $(schemafiles_DATA) $(ydata_DATA) $(desktop_DATA) $(ywidgets_DATA)

include $(top_srcdir)/Makefile.am.common

# Sources for country

module_DATA = \
  modules/Keyboard.rb

client_DATA = \
  clients/keyboard_auto.rb \
  clients/keyboard_proposal.rb \
  clients/keyboard.rb

schemafilesdir = $(schemadir)/autoyast/rnc
schemafiles_DATA = \
  autoyast-rnc/keyboard.rnc

desktop_DATA = \
  desktop/org.opensuse.yast.Keyboard.desktop

ywidgetsdir = @ylibdir@/y2country/widgets
ywidgets_DATA = \
  lib/y2country/widgets/keyboard_selection.rb

ylibdir = @ylibdir@/y2keyboard
ylib_DATA = \
  lib/y2keyboard/keyboard_layout_loader.rb \
  lib/y2keyboard/keyboard_layout.rb \
  lib/y2keyboard/keyboards.rb

ylibclientsdir = @ylibdir@/y2keyboard/clients
ylibclients_DATA = \
  lib/y2keyboard/clients/keyboard.rb \
  lib/y2keyboard/clients/keyboard_proposal.rb \
  lib/y2keyboard/clients/keyboard_auto.rb

ylibdialogsdir = @ylibdir@/y2keyboard/dialogs
ylibdialogs_DATA = \
  lib/y2keyboard/dialogs/layout_selector.rb

ylibstrategiesdir = @ylibdir@/y2keyboard/strategies
ylibstrategies_DATA = \
  lib/y2keyboard/strategies/systemd_strategy.rb \
  lib/y2keyboard/strategies/kb_strategy.rb \
  lib/y2keyboard/strategies/yast_proposal_strategy.rb

symbolicdir = @icondir@/hicolor/symbolic/apps
symbolic_DATA = \
  icons/hicolor/symbolic/apps/yast-keyboard-symbolic.svg
scalabledir = @icondir@/hicolor/scalable/apps
scalable_DATA = \
  icons/hicolor/scalable/apps/yast-keyboard.svg

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(scrconf_DATA) \
  $(schemafiles_DATA) $(desktop_DATA) $(ywidgets_DATA) $(ylib_DATA) \
  $(ylibclients_DATA) $(ylibdialogs_DATA) $(ylibstrategies_DATA) \
  $(symbolic_DATA) $(scalable_DATA)

include $(top_srcdir)/Makefile.am.common

# Sources for country

module_DATA = \
  modules/Timezone.rb

module1dir = @moduledir@/YaPI
module1_DATA = \
  modules/YaPI/TIME.pm

client_DATA = \
  clients/inst_timezone.rb \
  clients/timezone_auto.rb \
  clients/timezone.rb \
  clients/timezone_proposal.rb

yncludedir = @yncludedir@/timezone
ynclude_DATA = \
  include/timezone/dialogs.rb

scrconf_DATA = \
  scrconf/sysconfig_clock.scr \
  scrconf/etc_adjtime.scr

schemafilesdir = $(schemadir)/autoyast/rnc
schemafiles_DATA = \
  autoyast-rnc/timezone.rnc

ydata_DATA = \
  data/lang2tz.ycp \
  data/timezone_raw.ycp

desktop_DATA = \
  desktop/org.opensuse.yast.Timezone.desktop

symbolicdir = @icondir@/hicolor/symbolic/apps
symbolic_DATA = \
  icons/hicolor/symbolic/apps/yast-timezone-symbolic.svg
scalabledir = @icondir@/hicolor/scalable/apps
scalable_DATA = \
  icons/hicolor/scalable/apps/yast-timezone.svg

EXTRA_DIST = $(module_DATA) $(module1_DATA) $(client_DATA) $(ynclude_DATA) $(scrconf_DATA) $(schemafiles_DATA) $(ydata_DATA) $(desktop_DATA) $(symbolic_DATA) $(scalable_DATA)

include $(top_srcdir)/Makefile.am.common

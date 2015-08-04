# Sources for country

module_DATA = \
  modules/Timezone.rb

module1dir = @moduledir@/YaPI
module1_DATA = \
  modules/YaPI/TIME.pm

client_DATA = \
  clients/inst_timezone.rb \
  clients/timezone.rb \
  clients/timezone_auto.rb \
  clients/timezone_ntp.rb \
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
  desktop/timezone.desktop

ylibdir = @ylibdir@/timezone
ylib_DATA = \
  lib/timezone/ntp.rb \
  lib/timezone/ntp_adapter.rb

EXTRA_DIST = $(module_DATA) $(module1_DATA) $(client_DATA) $(ynclude_DATA) $(scrconf_DATA) $(schemafiles_DATA) $(ydata_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common

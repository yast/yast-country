# Makefile.am for country/timezone/src

SUBDIRS = proposal

yncludedir = @yncludedir@/timezone

client_DATA =			\
	timezone.ycp		\
	inst_timezone.ycp	\
	timezone_auto.ycp

desktop_DATA =			\
	timezone.desktop

module_DATA = 			\
	Timezone.ycp

ynclude_DATA =			\
	dialogs.ycp

EXTRA_DIST = $(client_DATA) $(module_DATA) $(desktop_DATA) $(ynclude_DATA)

YCPCFLAGS = -M ../../language/src/modules

include $(top_srcdir)/Makefile.am.common

# Makefile.am for country/timezone/src

SUBDIRS = proposal

client_DATA =			\
	timezone.ycp		\
	inst_timezone.ycp

desktop_DATA =			\
	timezone.desktop

module_DATA = 			\
	Timezone.ycp

EXTRA_DIST = $(client_DATA) $(module_DATA) $(desktop_DATA)

YCPCFLAGS = -M ../../language/src/modules

include $(top_srcdir)/Makefile.am.common

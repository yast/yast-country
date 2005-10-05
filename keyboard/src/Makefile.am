# Makefile.am for country/keyboard/src

SUBDIRS = modules proposal

yncludedir = @yncludedir@/keyboard

client_DATA =				\
	keyboard.ycp			\
	keyboard_auto.ycp

ynclude_DATA =				\
	dialogs.ycp

desktop_DATA =				\
	keyboard.desktop

EXTRA_DIST = $(client_DATA) $(desktop_DATA) $(ynclude_DATA)

include $(top_srcdir)/Makefile.am.common

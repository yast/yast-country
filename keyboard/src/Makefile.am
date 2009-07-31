# Makefile.am for country/keyboard/src

SUBDIRS = modules proposal

yncludedir = @yncludedir@/keyboard

rncdir =  $(schemadir)/autoyast/rnc

client_DATA =				\
	keyboard.ycp			\
	keyboard_auto.ycp

ynclude_DATA =				\
	dialogs.ycp

rnc_DATA = keyboard.rnc

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(rnc_DATA)

include $(top_srcdir)/Makefile.am.common

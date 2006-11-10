# Makefile.am for country/language/src

rncdir =  $(schemadir)/autoyast/rnc

SUBDIRS = modules proposal

client_DATA =			\
	language.ycp		\
	inst_language.ycp	\
	select_language.ycp	\
	language_auto.ycp

desktop_DATA =			\
	yast-language.desktop

rnc_DATA =	language.rnc

EXTRA_DIST = $(client_DATA) $(desktop_DATA) $(rnc_DATA)

include $(top_srcdir)/Makefile.am.common

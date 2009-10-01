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

YaPI_perldir = @moduledir@/YaPI

YaPI_perl_DATA = \
    YaPI/LANGUAGE.pm


EXTRA_DIST = $(client_DATA) $(desktop_DATA) $(YaPI_perl_DATA) $(rnc_DATA)

include $(top_srcdir)/Makefile.am.common

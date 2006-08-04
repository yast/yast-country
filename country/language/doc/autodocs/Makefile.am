#
# Makefile.am for country/language/doc/autodocs

htmldir = @docdir@/autodocs

html_DATA = index.html $(wildcard *.html)
CLEANFILES = $(html_DATA)

index.html: $(srcdir)/../../src/*.ycp $(srcdir)/../../src/*/*.ycp
	${YCPDOC} -d. $^

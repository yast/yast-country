#
# Makefile.am for country/keyboard/doc/autodocs

htmldir = @docdir@/autodocs

html_DATA = index.html $(wildcard *.html)
CLEANFILES = $(html_DATA)

index.html: $(srcdir)/../../src/*.ycp $(srcdir)/../../src/*/*.ycp
	@ybindir@/ycpdoc -d. $^

#
# Makefile.am for country/language/agents
#
scrconf_DATA = $(patsubst $(srcdir)/%,%,$(wildcard $(srcdir)/*.scr))

EXTRA_DIST = $(scrconf_DATA)

agentdir = $(execcompdir)/servers_non_y2
agent_SCRIPTS = ag_fvwm2_setlang

EXTRA_DIST += $(agent_SCRIPTS)


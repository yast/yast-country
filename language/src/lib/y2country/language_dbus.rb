# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2012 Novell, Inc. All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------

# File:	modules/Language.ycp
# Module:	Language
# Summary:	DBus interface for localed.conf
# Authors:	Klaus Kaempf <kkaempf@suse.de>
#		Thomas Roelz <tom@suse.de>
# Maintainer:  Jiri Suchomel <jsuchome@suse.cz>
#
# $Id$
require "yast"

module Y2Country
    extend Yast::Logger

    # Read via DBus the locale settings
    # @return hash of locale variables
    def read_locale_conf
      begin
        require "dbus"
      rescue
        # inst-sys (because of constructor)
        log.info("DBus module not available")
        return nil
      end
      localed_conf = {}
      # https://www.freedesktop.org/wiki/Software/systemd/localed/
      sysbus = DBus.system_bus
      locale_service   = sysbus["org.freedesktop.locale1"]
      locale_object    = locale_service.object "/org/freedesktop/locale1"
      locale_object.introspect # needed, ask mvidner for explanation
      locale_interface = locale_object["org.freedesktop.locale1"]
      locales          = locale_interface["Locale"]
      locales[0].split(',').each do | locale |
        parsed = locale.split('=')
        key = parsed[0]
        localed_conf[key] = parsed[1]
      end
      log.info("Locale settings read from system: #{localed_conf}")      
      localed_conf
    end

    module_function :read_locale_conf
end

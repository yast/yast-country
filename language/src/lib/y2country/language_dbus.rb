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

# File:	lib/y2country/language_dbus.rb
# Module:	Language
# Summary:	DBus interface for localed.conf
# Authors:	Jiri Srain <jsrain@suse.de>
#
# $Id$
require "yast"

module Y2Country
    extend Yast::Logger

    # Read via DBus the locale settings
    # @return [Hash] locale variables
    def read_locale_conf
      # dbus not available
      return nil unless File.exists?("/var/run/dbus/system_bus_socket")

      begin
        require "dbus"
      rescue LoadError
        # inst-sys (because of constructor)
        log.info("DBus module not available")
        return nil
      end
      localed_conf = {}
      begin
        # https://www.freedesktop.org/wiki/Software/systemd/localed/
        sysbus = DBus.system_bus
        locale_service   = sysbus["org.freedesktop.locale1"]
        locale_object    = locale_service.object "/org/freedesktop/locale1"
        # following line not necessary with ruby-dbus >= 0.13.0
        locale_object.introspect # needed, https://github.com/mvidner/ruby-dbus/issues/28
        locale_interface = locale_object["org.freedesktop.locale1"]
        locales          = locale_interface["Locale"]
        locales[0].split(',').each do | locale |
          parsed = locale.split('=', 2)
          key = parsed[0]
          localed_conf[key] = parsed[1]
        end
      rescue => e
        log.error "Dbus reading failed with #{e.message}"
        return nil
      end
      log.info("Locale settings read from system: #{localed_conf}")
      localed_conf
    end

    module_function :read_locale_conf
end

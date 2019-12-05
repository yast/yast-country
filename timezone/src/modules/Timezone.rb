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
# File:	modules/Timezone.ycp
# Package:	Country settings
# Summary:	Timezone related stuff
# Authors:	Klaus Kaempf <kkaempf@suse.de>
#		Thomas Roelz <tom@suse.de>

require "yast"

begin
  require "y2storage"
rescue LoadError
  # Ignore y2storage not being available (bsc#1058869)
end

module Yast
  class TimezoneClass < Module
    include Yast::Logger

    def main
      textdomain "country"

      Yast.import "Arch"
      Yast.import "FileUtils"
      Yast.import "Language"
      Yast.import "Misc"
      Yast.import "Mode"
      Yast.import "Stage"
      Yast.import "String"
      Yast.import "ProductFeatures"

      # --------------------------------------------------------------
      # START: Globally defined data to be accessed via Timezone::<variable>
      # --------------------------------------------------------------

      @timezone = "" # e.g. "Europe/Berlin"

      # hwclock parameter
      # possible values:
      #	 ""		dont change timezone
      #	 "-u"		system clock runs UTC
      #   "--localtime"	system clock runs localtime
      @hwclock = ""

      # The default timezone if set.
      #
      @default_timezone = ""

      # Flag indicating if the user has chosen a timezone.
      # To be set from outside.
      #
      @user_decision = false
      @user_hwclock = false

      # If NTP is configured
      @ntp_used = false

      @diff = 0

      # if anyuthing was modified (currently for auto client only)
      @modified = false

      # If there is windows partition, assume that local time is used
      @windows_partition = false

      # if mkinitrd should be called at the end
      @call_mkinitrd = false

      # translation of correct timezone to the one that could be shown in map widget
      @yast2zonetab = {
        "Mideast/Riyadh87" => "Asia/Riyadh",
        "Mideast/Riyadh88" => "Asia/Riyadh",
        "Mideast/Riyadh89" => "Asia/Riyadh",
        "Europe/Vatican"   => "Europe/Rome"
      }

      # on init, translate these to correct ones
      @obsoleted_zones = {
        "Iceland"                  => "Atlantic/Reykjavik",
        "Europe/Belfast"           => "Europe/London",
        "Australia/South"          => "Australia/Adelaide",
        "Australia/North"          => "Australia/Darwin",
        "Australia/NSW"            => "Australia/Sydney",
        "Australia/ACT"            => "Australia/Canberra",
        "Australia/Queensland"     => "Australia/Brisbane",
        "Australia/Tasmania"       => "Australia/Hobart",
        "Australia/Victoria"       => "Australia/Melbourne",
        "Australia/West"           => "Australia/Perth",
        "US/Alaska"                => "America/Anchorage",
        "US/Aleutian"              => "America/Adak",
        "US/Arizona"               => "America/Phoenix",
        "US/Central"               => "America/Chicago",
        "US/East-Indiana"          => "America/Indiana/Indianapolis",
        "US/Hawaii"                => "Pacific/Honolulu",
        "US/Indiana-Starke"        => "America/Indiana/Knox",
        "US/Michigan"              => "America/Detroit",
        "US/Mountain"              => "America/Denver",
        "US/Pacific"               => "America/Los_Angeles",
        "US/Samoa"                 => "Pacific/Pago_Pago",
        "US/Eastern"               => "America/New_York",
        "Canada/Atlantic"          => "America/Halifax",
        "Canada/Central"           => "America/Winnipeg",
        "Canada/Eastern"           => "America/Toronto",
        "Canada/Saskatchewan"      => "America/Regina",
        "Canada/East-Saskatchewan" => "America/Regina",
        "Canada/Mountain"          => "America/Edmonton",
        "Canada/Newfoundland"      => "America/St_Johns",
        "Canada/Pacific"           => "America/Vancouver",
        "Canada/Yukon"             => "America/Whitehorse",
        "America/Buenos_Aires"     => "America/Argentina/Buenos_Aires",
        "America/Virgin"           => "America/St_Thomas",
        "Brazil/Acre"              => "America/Rio_Branco",
        "Brazil/East"              => "America/Sao_Paulo",
        "Brazil/West"              => "America/Manaus",
        "Chile/Continental"        => "America/Santiago",
        "Chile/EasterIsland"       => "Pacific/Easter",
        "Mexico/BajaNorte"         => "America/Tijuana",
        "Mexico/BajaSur"           => "America/Mazatlan",
        "Mexico/General"           => "America/Mexico_City",
        "Jamaica"                  => "America/Jamaica",
        "Asia/Macao"               => "Asia/Macau",
        "Israel"                   => "Asia/Jerusalem",
        "Asia/Tel_Aviv"            => "Asia/Jerusalem",
        "Hongkong"                 => "Asia/Hong_Kong",
        "Japan"                    => "Asia/Tokyo",
        "ROK"                      => "Asia/Seoul",
        "Africa/Timbuktu"          => "Africa/Bamako",
        "Egypt"                    => "Africa/Cairo"
      }
      # ------------------------------------------------------------------
      # END: Globally defined data to be accessed via Timezone::<variable>
      # ------------------------------------------------------------------



      # ------------------------------------------------------------------
      # START: Locally defined data
      # ------------------------------------------------------------------

      # internal map used to store initial data
      @push = {}


      @name = ""

      # list with maps, each map provides time zone information about one region
      @zonemap = []

      # 'language --> default timezone' conversion map
      @lang2tz = {}

      # remember if /sbin/hwclock --hctosys was called, it can be done only once (bnc#584484)
      @systz_called = false

      # timezone is read-only
      @readonly = nil

      Timezone()
    end

    # ------------------------------------------------------------------
    # END: Locally defined data
    # ------------------------------------------------------------------


    # -----------------------------------------------------------------------------
    # START: Globally defined functions
    # -----------------------------------------------------------------------------

    # get_lang2tz()
    #
    # Get the language --> timezone conversion map.
    #
    # @return  conversion map
    #
    # @see #get_zonemap()

    def get_lang2tz
      if Builtins.size(@lang2tz) == 0
        base_lang2tz = Convert.to_map(
          SCR.Read(path(".target.yast2"), "lang2tz.ycp")
        )
        base_lang2tz = {} if base_lang2tz == nil

        @lang2tz = Convert.convert(
          Builtins.union(base_lang2tz, Language.GetLang2TimezoneMap(true)),
          :from => "map",
          :to   => "map <string, string>"
        )
      end
      deep_copy(@lang2tz)
    end

    # get_zonemap()
    #
    # Get the timezone database.
    #
    # @return  timezone DB (map)
    #
    # @see #get_lang2tz()

    def get_zonemap
      if Builtins.size(@zonemap) == 0
        zmap = Convert.convert(
          Builtins.eval(SCR.Read(path(".target.yast2"), "timezone_raw.ycp")),
          :from => "any",
          :to   => "list <map <string, any>>"
        )
        zmap = [] if zmap == nil

        @zonemap = Builtins.sort(zmap) do |a, b|
          # [ "USA", "Canada" ] -> [ "Canada", "USA" ]
          # bnc#385172: must use < instead of <=, the following means:
          # strcoll(x) <= strcoll(y) && strcoll(x) != strcoll(y)
          lsorted = Builtins.lsort(
            [Ops.get_string(a, "name", ""), Ops.get_string(b, "name", "")]
          )
          lsorted_r = Builtins.lsort(
            [Ops.get_string(b, "name", ""), Ops.get_string(a, "name", "")]
          )
          Ops.get_string(lsorted, 0, "") == Ops.get_string(a, "name", "") &&
            lsorted == lsorted_r
        end
      end
      deep_copy(@zonemap)
    end

    # ------------------------------------------------------------------
    # END: Locally defined functions
    # ------------------------------------------------------------------
    # Set()
    #
    # Set system to selected timezone.
    #
    # @param	string timezone to select, e.g. "Europe/Berlin"
    #
    # @return	the number of the region that contains the timezone
    #
    def Set(zone, really)
      # Do not update the timezone if it's forced and it was already set
      if (Mode.installation || Mode.update) && readonly && !@timezone.empty?
        log.info "Timezone is read-only and cannot be changed during installation"
      else
        # Set the new timezone internally
        @timezone = zone
      end

      zmap = get_zonemap

      sel = 0
      while Ops.less_than(sel, Builtins.size(zmap)) &&
          !Builtins.haskey(Ops.get_map(zmap, [sel, "entries"], {}), @timezone)
        sel = Ops.add(sel, 1)
      end

      @name = Ops.add(
        Ops.add(Ops.get_string(zmap, [sel, "name"], ""), " / "),
        Ops.get_string(zmap, [sel, "entries", @timezone], @timezone)
      )

      # Adjust system to the new timezone.
      #
      if !Mode.config && really
        textmode = Language.GetTextMode
        # turn off the screensaver when clock can change radically (bnc#455771)
        # (in non-firstboot cases, installation process handles it)
        if Stage.firstboot && !textmode
          SCR.Execute(path(".target.bash"), "/usr/bin/xset -dpms")
          SCR.Execute(path(".target.bash"), "/usr/bin/xset s reset")
          SCR.Execute(path(".target.bash"), "/usr/bin/xset s off")
        end
        cmd = Ops.add("/usr/sbin/zic -l ", @timezone)
        Builtins.y2milestone("Set cmd %1", cmd)
        Builtins.y2milestone(
          "Set ret %1",
          SCR.Execute(path(".target.bash_output"), cmd)
        )
        unless Stage.initial
          cmd = "/bin/systemctl try-restart systemd-timedated.service"
          Builtins.y2milestone(
            "restarting timedated service: %1",
            SCR.Execute(path(".target.bash_output"), cmd)
          )
        end
        if !Arch.s390
          cmd = Ops.add("/sbin/hwclock --hctosys ", @hwclock)
          if Stage.initial && @hwclock == "--localtime"
            if !@systz_called
              cmd = "/sbin/hwclock --systz --localtime --noadjfile && touch /dev/shm/warpclock"
              @systz_called = true
            end
          end
          Builtins.y2milestone("Set cmd %1", cmd)
          Builtins.y2milestone(
            "Set ret %1",
            SCR.Execute(path(".target.bash_output"), cmd)
          )
        end
        if Stage.firstboot && !textmode
          SCR.Execute(path(".target.bash"), "/usr/bin/xset s on")
          SCR.Execute(path(".target.bash"), "/usr/bin/xset +dpms")
        end
      end

      # On first assignment store default timezone.
      #
      if @default_timezone == ""
        @default_timezone = @timezone
        Builtins.y2milestone("Set default timezone: <%1>", @timezone)
      end

      Builtins.y2milestone(
        "Set timezone:%1 sel:%2 name:%3",
        @timezone,
        sel,
        @name
      )
      sel
    end

    # Convert the duplicated timezone to the only one supported
    # Temporary solution - a result of discussion of bug #47472
    # @param [String] tmz current timezone
    def UpdateTimezone(tmz)
      updated_tmz = tmz

      if Builtins.haskey(@obsoleted_zones, tmz)
        updated_tmz = Ops.get(@obsoleted_zones, tmz, tmz)
        Builtins.y2milestone(
          "updating timezone from %1 to %2",
          tmz,
          updated_tmz
        )
      end

      updated_tmz
    end

    # Read the content of /etc/adjtime
    def ReadAdjTime
      cont = Convert.convert(
        SCR.Read(path(".etc.adjtime")),
        :from => "any",
        :to   => "list <string>"
      )
      if cont == nil
        Builtins.y2warning("/etc/adjtime not available or not readable")
      end
      if Builtins.size(cont) != 3
        Builtins.y2warning("/etc/adjtime has wrong number of lines: %1", cont)
        cont = nil
      end
      deep_copy(cont)
    end


    # Read timezone settings from sysconfig
    def Read
      @default_timezone = Misc.SysconfigRead(
        path(".sysconfig.clock.DEFAULT_TIMEZONE"),
        @default_timezone
      )
      @timezone = @default_timezone

      # /etc/localtime has priority over sysconfig value of timezone
      if FileUtils.IsLink("/etc/localtime")
        tz_file = Convert.to_string(
          SCR.Read(path(".target.symlink"), "/etc/localtime")
        )
        if tz_file != nil &&
            Builtins.substring(tz_file, 0, 20) == "/usr/share/zoneinfo/"
          @timezone = Builtins.substring(tz_file, 20)
          Builtins.y2milestone(
            "time zone read from /etc/localtime: %1",
            @timezone
          )
        end
      end

      adjtime = ReadAdjTime()
      if Builtins.size(adjtime) == 3
        if Ops.get(adjtime, 2, "") == "LOCAL"
          @hwclock = "--localtime"
        elsif Ops.get(adjtime, 2, "") == "UTC"
          @hwclock = "-u"
        end
        Builtins.y2milestone("content of /etc/adjtime: %1", adjtime)
      else
        # use sysconfig value as a backup (if available)
        @hwclock = Misc.SysconfigRead(
          path(".sysconfig.clock.HWCLOCK"),
          @hwclock
        )
      end

      # get name for cloning purposes
      if Mode.config
        zmap = get_zonemap
        sel = 0
        while Ops.less_than(sel, Builtins.size(zmap)) &&
            !Builtins.haskey(Ops.get_map(zmap, [sel, "entries"], {}), @timezone)
          sel = Ops.add(sel, 1)
        end
        @name = Ops.add(
          Ops.add(Ops.get_string(zmap, [sel, "name"], ""), " / "),
          Ops.get_string(zmap, [sel, "entries", @timezone], @timezone)
        )
      end

      nil
    end

    # Timezone()
    #
    # The module constructor.
    # Sets the proprietary module data defined globally for public access.
    # This is done only once (and automatically) when the module is loaded for the first time.
    # Calls Set() in initial mode.
    # Reads current timezone from sysconfig in normal mode.
    #
    # @see #Set()
    def Timezone
      # Set default values.
      #
      @hwclock = "-u"
      if Stage.initial && !Mode.live_installation
        # language --> timezone database, e.g. "de_DE" : "Europe/Berlin"
        new_timezone =
          if readonly
            product_default_timezone
          else
            lang2tz = get_lang2tz
            Ops.get(lang2tz, Language.language, "")
          end

        Builtins.y2milestone("Timezone new_timezone %1", new_timezone)

        Set(new_timezone, true) if new_timezone != ""
      elsif !Mode.config
        Read()
      end
      nil
    end

    def CallMkinitrd
      Builtins.y2milestone("calling mkinitrd...")
      SCR.Execute(
        path(".target.bash"),
        "/sbin/mkinitrd >> /var/log/YaST2/y2logmkinitrd 2>> /var/log/YaST2/y2logmkinitrd"
      )
      Builtins.y2milestone("... done")
      true
    end


    # Set the new time and date given by user
    def SetTime(year, month, day, hour, minute, second)
      return nil if Arch.s390

      timedate = "#{month}/#{day}/#{year} #{hour}:#{minute}:#{second}"

      if set_hwclock(timedate)
        sync_hwclock_to_system_time
      else
        # No hardware clock available (bsc#1103744)
        log.info("Fallback: Leaving HW clock untouched, setting only system time")
        set_system_time(timedate)
      end
      nil
    end

    # Set the Hardware Clock to the current System Time.
    def SystemTime2HWClock
      return nil if Arch.s390

      cmd = tz_prefix + "/sbin/hwclock --systohc #{@hwclock}"
      log.info("cmd #{cmd}")
      SCR.Execute(path(".target.bash"), cmd)
      nil
    end

    # Set the hardware clock with the given date.
    # @param timedate [String]
    # @return [Bool] true if success, false if error
    #
    def set_hwclock(date)
      cmd = tz_prefix + "/sbin/hwclock --set #{@hwclock} --date=\"#{date}\""
      log.info("set_hwclock: #{cmd}")
      SCR.Execute(path(".target.bash"), cmd) == 0
    end

    # Synchronize the hardware clock to the system time
    #
    def sync_hwclock_to_system_time
      cmd = "/sbin/hwclock --hctosys #{@hwclock}"
      log.info("sync_hwclock_to_system_time: #{cmd}")
      SCR.Execute(path(".target.bash"), cmd)
      @systz_called = true
    end

    # Set only the system time (leaving the hardware clock untouched)
    # @param timedate [String]
    #
    def set_system_time(timedate)
      cmd = tz_prefix + "/usr/bin/date --set=\"#{timedate}\""
      log.info("set_system_time: #{cmd}")
      SCR.Execute(path(".target.bash"), cmd)
    end

    # Return a "TZ=... " prefix for commands such as "hwclock" or "date" to set
    # the time zone environment variable temporarily for the duration of one
    # command.
    #
    # If nonempty, this will append a blank as a separator.
    #
    # @return [String]
    #
    def tz_prefix
      return "" if @hwclock == "--localtime"
      return "" if @timezone.empty?
      "TZ=#{@timezone} "
    end


    # GetTimezoneForLanguage()
    #
    # Get the timezone for the given system language.
    #
    # @param	System language code, e.g. "en_US".
    #		Default timezone to be returned if nothing found.
    #
    # @return  The timezone for this language, e.g. "US/Eastern"
    #		or the default value if nothing found.
    #
    # @see #-
    def GetTimezoneForLanguage(sys_language, default_timezone)
      # The system_language --> timezone conversion map.
      #
      lang2timezone = get_lang2tz
      ret = Ops.get(lang2timezone, sys_language, default_timezone)

      Builtins.y2milestone(
        "language %1 default timezone %2 returned timezone %3",
        sys_language,
        default_timezone,
        ret
      )
      ret
    end

    # Set the timezone for the given system language.
    # @param	System language code, e.g. "en_US".
    # @return the number of the region that contains the timezone
    def SetTimezoneForLanguage(sys_language)
      tmz = GetTimezoneForLanguage(sys_language, "US/Eastern")
      Builtins.y2debug("language %1 proposed timezone %2", sys_language, tmz)
      Set(tmz, true) if tmz != ""

      nil
    end

    # Return the language code for given timezone (by reverse searching the
    # "language -> timezone" map)
    # @param timezone, if empty the current one is used
    def GetLanguageForTimezone(tz)
      tz = @timezone if tz == "" || tz == nil

      lang = ""
      Builtins.foreach(get_lang2tz) do |code, tmz|
        if tmz == tz && (lang == "" || !Builtins.issubstring(lang, "_"))
          lang = code
        end
      end
      lang
    end

    # Return the country part of language code for given timezone
    # @param timezone, if empty the current one is used
    def GetCountryForTimezone(tz)
      Language.GetGivenLanguageCountry(GetLanguageForTimezone(tz))
    end

    # Return translated country name of given timezone
    # @param timezone value (as saved in sysconfig/clock)
    def GetTimezoneCountry(zone)
      zmap = Convert.to_list(
        Builtins.eval(SCR.Read(path(".target.yast2"), "timezone_raw.ycp"))
      )

      sel = 0
      while Ops.less_than(sel, Builtins.size(zmap)) &&
          !Builtins.haskey(Ops.get_map(zmap, [sel, "entries"], {}), zone)
        sel = Ops.add(sel, 1)
      end
      Ops.add(
        Ops.add(Ops.get_string(zmap, [sel, "name"], ""), " / "),
        Ops.get_string(zmap, [sel, "entries", zone], zone)
      )
    end

    # GetDateTime()
    #
    # Get the output of date "+%H:%M:%S - %Y-%m-%d" or in locale defined format
    #
    # @param	flag if to get real system time or if to simulate changed
    #		timezone settings with TZ=
    # @param	if the date and time should be returned in locale defined format
    #
    # @return  The string output.
    #
    def GetDateTime(real_time, locale_format)
      cmd = ""

      date_format = locale_format && Mode.normal ?
        "+%c" :
        "+%Y-%m-%d - %H:%M:%S"

      log.info("GetDateTime hwclock: #{@hwclock} real: #{real_time}")
      if !real_time && !Mode.config
        ds = 0
        if @diff != 0
          out2 = Convert.to_map(
            SCR.Execute(path(".target.bash_output"), "date +%z")
          )
          tzd = Ops.get_string(out2, "stdout", "")
          log.info("GetDateTime tzd: #{tzd}")
          t = Builtins.tointeger(String.CutZeros(Builtins.substring(tzd, 1, 2)))
          if t != nil
            ds = Ops.add(ds, Ops.multiply(t, 3600))
            t = Builtins.tointeger(
              String.CutZeros(Builtins.substring(tzd, 3, 2))
            )
            ds = Ops.add(ds, Ops.multiply(t, 60))
            ds = Ops.unary_minus(ds) if Builtins.substring(tzd, 0, 1) == "-"
            log.info("GetDateTime ds: #{ds} diff: #{@diff}")
          end
        end
        cmd = tz_prefix +
          Builtins.sformat(
            "/bin/date \"%1\" \"--date=now %2sec\"",
            date_format,
            Ops.multiply(ds, @diff)
          )
      else
        cmd = Builtins.sformat("/bin/date \"%1\"", date_format)
      end
      log.info("GetDateTime cmd: #{cmd}")
      out = Convert.to_map(SCR.Execute(path(".target.bash_output"), cmd))
      local_date = Builtins.deletechars(Ops.get_string(out, "stdout", ""), "\n")

      log.info("GetDateTime local_date: '#{local_date}'")

      local_date
    end

    # Clear the internal map with timezones, so the timezone data could be
    # retranslated next time when they are needed
    def ResetZonemap
      @zonemap = []

      nil
    end

    # Return true if localtime should be proposed as default
    # Based on current hardware configuration:
    # Win partitions present or 32bit Mac
    def ProposeLocaltime
      vmware = SCR.Read(path(".probe.is_vmware"))
      @windows_partition || vmware || (Arch.board_mac && Arch.ppc32)
    end


    # Return proposal list of strings.
    #
    # @param [Boolean] force_reset
    #		boolean language_changed
    #
    # @return	[Array] user readable description.
    #
    # If force_reset is true reset the module to the timezone
    # stored in default_timezone.
    def MakeProposal(force_reset, language_changed)
      Builtins.y2milestone("force_reset: %1", force_reset)
      Builtins.y2milestone(
        "language_changed: %1 user_decision %2 user_hwclock %3",
        language_changed,
        @user_decision,
        @user_hwclock
      )

      ResetZonemap() if language_changed

      if !@user_hwclock || force_reset
        @hwclock = "-u"
        @hwclock = "--localtime" if ProposeLocaltime()
      end
      if force_reset
        # If user wants to reset do it if a default is available.
        #
        if @default_timezone != ""
          Set(@default_timezone, true) # reset
        end

        # Reset user_decision flag.
        #
        @user_decision = false # no reset
      else
        # Only follow the language if the user has never actively chosen
        # a timezone. The indicator for this is user_decision which is
        # set from outside the module.
        #
        if @user_decision || Mode.autoinst ||
            ProductFeatures.GetStringFeature("globals", "timezone") != ""
          if language_changed
            Builtins.y2milestone(
              "User has chosen a timezone; not following language - only retranslation."
            )

            Set(@timezone, true)
          end
        else
          # User has not yet chosen a timezone ==> follow language.
          #
          local_timezone = GetTimezoneForLanguage(
            Language.language,
            "US/Eastern"
          )

          if local_timezone != ""
            Set(local_timezone, true)
            @default_timezone = local_timezone
          else
            if language_changed
              Builtins.y2error("Can't follow language - only retranslation")

              Set(@timezone, true)
            end
          end
        end
      end

      # label text (Clock setting)
      clock_setting = _("UTC")

      if @hwclock == "--localtime"
        # label text, Clock setting: local time (not UTC)
        clock_setting = _("Local Time")
      end

      # label text
      clock_setting = Ops.add(_("Hardware Clock Set To") + " ", clock_setting)

      date = GetDateTime(true, true)

      Builtins.y2milestone("MakeProposal hwclock %1", @hwclock)

      ret = [
        Ops.add(
          Ops.add(Ops.add(Ops.add(@name, " - "), clock_setting), " "),
          date
        )
      ]
      if @ntp_used
        # summary label
        ret = Builtins.add(ret, _("NTP configured"))
      end
      deep_copy(ret)
    end

    # Selection()
    #
    # Return a map of ids and names to build up a selection list
    # for the user. The key is used later in the Set function
    # to select this timezone. The name is a translated string.
    #
    # @param	-
    #
    # @return	[Hash]	map for timezones
    #			'timezone_id' is used internally in Set and Probe
    #			functions. 'timezone_name' is a user-readable string.
    #			Uses Language::language for translation.
    # @see #Set()

    def Selection(num)
      zmap = get_zonemap

      trl = Builtins.maplist(Ops.get_map(zmap, [num, "entries"], {})) do |key, name|
        [name, key]
      end

      trl = Builtins.sort(trl) do |a, b|
        # bnc#385172: must use < instead of <=, the following means:
        # strcoll(x) <= strcoll(y) && strcoll(x) != strcoll(y)
        lsorted = Builtins.lsort([Ops.get(a, 0, ""), Ops.get(b, 0, "")])
        lsorted_r = Builtins.lsort([Ops.get(b, 0, ""), Ops.get(a, 0, "")])
        Ops.get_string(lsorted, 0, "") == Ops.get(a, 0, "") &&
          lsorted == lsorted_r
      end
      Builtins.y2debug("trl = %1", trl)

      Builtins.maplist(trl) do |e|
        Item(Id(Ops.get_string(e, 1, "")), Ops.get_string(e, 0, ""), false)
      end
    end

    # Return list of regions for timezone selection list
    def Region
      num = -1
      Builtins.maplist(get_zonemap) do |entry|
        num = Ops.add(num, 1)
        Item(Id(num), Ops.get_string(entry, "name", ""), false)
      end
    end


    # Save()
    #
    # Save timezone to target sysconfig.
    def Save
      if Mode.mode == "update"
        Builtins.y2milestone("not saving in update mode...")
        return
      end

      cmd = if Stage.initial
        # do use --root option, running in chroot does not work
        "/usr/bin/systemd-firstboot --root '#{Installation.destdir}' --timezone '#{@timezone}'"
      else
        # this sets both the locale (see "man localectl")
        "/usr/bin/timedatectl set-timezone #{@timezone}"
      end
      log.info "Making timezone setting persistent: #{cmd}"
      result = if Stage.initial
        WFM.Execute(path(".local.bash_output"), cmd)
      else
        SCR.Execute(path(".target.bash_output"), cmd)
      end
      if result["exit"] != 0
        log.error "Timezone configuration not written. Failed to execute '#{cmd}'"
        log.error "output: #{result.inspect}"
        # TRANSLATORS: the "%s" is replaced by the executed command
        Report.Error(_("Could not save the timezone setting, the command\n%s\nfailed.") % cmd)
      else
        log.info "output: #{result.inspect}"
      end

      SCR.Write(path(".sysconfig.clock.DEFAULT_TIMEZONE"), @default_timezone)

      SCR.Write(path(".sysconfig.clock"), nil) # flush

      Builtins.y2milestone("Save Saved data for timezone: <%1>", @timezone)

      adjtime = ReadAdjTime()
      if adjtime.nil? || adjtime.size == 3
        new     = adjtime.nil? ? ["0.0 0 0.0", "0"] : adjtime.dup
        new[2]  = @hwclock == "-u" ? "UTC" : "LOCAL"
        if adjtime.nil? || new[2] != adjtime[2]
          SCR.Write(path(".etc.adjtime"), new)
          Builtins.y2milestone("Saved /etc/adjtime with '%1'", new[2])
        end
      end

      CallMkinitrd() if @call_mkinitrd && !Stage.initial

      nil
    end


    # Return current date and time in the map
    def GetDateTimeMap
      ret = {}
      dparts = Builtins.filter(
        Builtins.splitstring(GetDateTime(false, false), " -:")
      ) { |v| Ops.greater_than(Builtins.size(v), 0) }

      Ops.set(ret, "year", Ops.get_string(dparts, 0, ""))
      Ops.set(ret, "month", Ops.get_string(dparts, 1, ""))
      Ops.set(ret, "day", Ops.get_string(dparts, 2, ""))
      Ops.set(ret, "hour", Ops.get_string(dparts, 3, ""))
      Ops.set(ret, "minute", Ops.get_string(dparts, 4, ""))
      Ops.set(ret, "second", Ops.get_string(dparts, 5, ""))

      Builtins.y2milestone("GetDateTimeMap dparts %1 ret %2", dparts, ret)
      deep_copy(ret)
    end

    def CheckTime(hour, minute, second)
      ret = true
      tmp = Builtins.tointeger(String.CutZeros(hour))
      return false if tmp == nil
      ret = ret && Ops.greater_or_equal(tmp, 0) && Ops.less_than(tmp, 24)
      tmp = Builtins.tointeger(String.CutZeros(minute))
      return false if tmp == nil
      ret = ret && Ops.greater_or_equal(tmp, 0) && Ops.less_than(tmp, 60)
      tmp = Builtins.tointeger(String.CutZeros(second))
      return false if tmp == nil
      ret = ret && Ops.greater_or_equal(tmp, 0) && Ops.less_than(tmp, 60)
      ret
    end

    def CheckDate(day, month, year)
      mdays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
      ret = true
      yea = Builtins.tointeger(String.CutZeros(year))
      mon = Builtins.tointeger(String.CutZeros(month))
      da = Builtins.tointeger(String.CutZeros(day))
      return false if yea == nil || mon == nil || da == nil
      ret = ret && Ops.greater_or_equal(mon, 1) && Ops.less_or_equal(mon, 12)
      if Ops.modulo(yea, 4) == 0 &&
          (Ops.modulo(yea, 100) != 0 || Ops.modulo(yea, 400) == 0)
        Ops.set(mdays, 1, 29)
      end
      ret = ret && Ops.greater_or_equal(da, 1) &&
        Ops.less_or_equal(da, Ops.get_integer(mdays, Ops.subtract(mon, 1), 0))
      ret = ret && Ops.greater_or_equal(yea, 1970) && Ops.less_than(yea, 2032)
      ret
    end

    # does the hwclock run on UTC only ? -> skip asking
    def utc_only
      Builtins.y2milestone(
        "Arch::sparc () %1 Arch::board_iseries () %2 Arch::board_chrp () %3 Arch::board_prep () %4",
        Arch.sparc,
        Arch.board_iseries,
        Arch.board_chrp,
        Arch.board_prep
      )

      Arch.sparc || Arch.board_iseries || Arch.board_chrp || Arch.board_prep
    end

    # save the initial data
    def PushVal
      @push = { "hwclock" => @hwclock, "timezone" => @timezone }
      Builtins.y2milestone("PushVal map %1", @push)

      nil
    end

    # restore the original data from internal map
    def PopVal
      Builtins.y2milestone(
        "before Pop: timezone %1 hwclock %2",
        @timezone,
        @hwclock
      )
      if Builtins.haskey(@push, "hwclock")
        @hwclock = Ops.get_string(@push, "hwclock", @hwclock)
      end
      if Builtins.haskey(@push, "timezone")
        @timezone = Ops.get_string(@push, "timezone", @timezone)
      end
      @push = {}
      Builtins.y2milestone(
        "after Pop: timezone %1 hwclock %2",
        @timezone,
        @hwclock
      )

      nil
    end

    # was anything modified?
    def Modified
      @modified || @timezone != Ops.get_string(@push, "timezone", @timezone) ||
        @hwclock != Ops.get_string(@push, "hwclock", @hwclock)
    end

    # AutoYaST interface function: Get the Timezone configuration from a map.
    # @param [Hash] settings imported map
    # @return success
    def Import(settings)
      settings = deep_copy(settings)
      # Read was not called -> do the init
      PushVal() if @push == {}

      if Builtins.haskey(settings, "hwclock")
        @hwclock = Ops.get_string(settings, "hwclock", "UTC") == "UTC" ? "-u" : "--localtime"
        @user_hwclock = true
      end
      Set(Ops.get_string(settings, "timezone", @timezone), true)
      true
    end

    # AutoYaST interface function: Return the Timezone configuration as a map.
    # @return [Hash] with the settings
    def Export
      ret = {
        "timezone" => @timezone,
        "hwclock"  => @hwclock == "-u" ? "UTC" : "localtime"
      }
      deep_copy(ret)
    end

    # AutoYaST interface function: Return the summary of Timezone configuration as a map.
    # @return summary string (html)
    def Summary
      Yast.import "HTML"

      clock_setting = _("UTC")

      if @hwclock == "--localtime"
        # label text, Clock setting: local time (not UTC)
        clock_setting = _("Local Time")
      end

      # label text
      clock_setting = Ops.add(_("Hardware Clock Set To") + " ", clock_setting)

      ret = [
        # summary label
        Builtins.sformat(_("Current Time Zone: %1"), @name),
        clock_setting
      ]
      HTML.List(ret)
    end

    # Checks whether the system has Windows installed
    #
    # @return [Boolean]
    def system_has_windows?
      # Avoid probing if the architecture is not supported for Windows
      return false unless windows_architecture?

      disk_analyzer.windows_system?
    rescue NameError => ex
      # bsc#1058869: Don't enforce y2storage being available
      log.warn("Caught #{ex}")
      log.warn("No storage-ng support - not checking for a windows partition")
      log.warn("Assuming UTC for the hardware clock")
      false # No windows partition found
    end

    # Determines whether timezone is read-only for the current product
    #
    # @return [Boolean] true if it's read-only; false otherwise.
    def readonly
      return @readonly unless @readonly.nil?
      @readonly = ProductFeatures.GetBooleanFeature("globals", "readonly_timezone")
    end

    # Product's default timezone when it's not defined in the control file.
    FALLBACK_PRODUCT_DEFAULT_TIMEZONE = "UTC"

    # Determines the default timezone for the current product
    #
    # If not timezone is set, FALLBACK_PRODUCT_DEFAULT_TIMEZONE will be used.
    # More information can be found on FATE#321754 and
    # https://github.com/yast/yast-installation/blob/master/doc/control-file.md#installation-and-product-variables
    #
    # @return [String] timezone
    def product_default_timezone
      product_timezone = ProductFeatures.GetStringFeature("globals", "timezone")
      product_timezone.empty? ? FALLBACK_PRODUCT_DEFAULT_TIMEZONE : product_timezone
    end

    publish :variable => :timezone, :type => "string"
    publish :variable => :hwclock, :type => "string"
    publish :variable => :default_timezone, :type => "string"
    publish :variable => :user_decision, :type => "boolean"
    publish :variable => :user_hwclock, :type => "boolean"
    publish :variable => :ntp_used, :type => "boolean"
    publish :variable => :diff, :type => "integer"
    publish :variable => :modified, :type => "boolean"
    publish :variable => :windows_partition, :type => "boolean"
    publish :variable => :call_mkinitrd, :type => "boolean"
    publish :variable => :yast2zonetab, :type => "map <string, string>"
    publish :variable => :obsoleted_zones, :type => "map <string, string>"
    publish :function => :get_zonemap, :type => "list <map <string, any>> ()"
    publish :function => :Set, :type => "integer (string, boolean)"
    publish :function => :UpdateTimezone, :type => "string (string)"
    publish :function => :Read, :type => "void ()"
    publish :function => :Timezone, :type => "void ()"
    publish :function => :CallMkinitrd, :type => "boolean ()"
    publish :function => :SetTime, :type => "void (string, string, string, string, string, string)"
    publish :function => :SystemTime2HWClock, :type => "void ()"
    publish :function => :GetTimezoneForLanguage, :type => "string (string, string)"
    publish :function => :SetTimezoneForLanguage, :type => "void (string)"
    publish :function => :GetLanguageForTimezone, :type => "string (string)"
    publish :function => :GetCountryForTimezone, :type => "string (string)"
    publish :function => :GetTimezoneCountry, :type => "string (string)"
    publish :function => :GetDateTime, :type => "string (boolean, boolean)"
    publish :function => :ResetZonemap, :type => "void ()"
    publish :function => :ProposeLocaltime, :type => "boolean ()"
    publish :function => :MakeProposal, :type => "list <string> (boolean, boolean)"
    publish :function => :Selection, :type => "list (integer)"
    publish :function => :Region, :type => "list ()"
    publish :function => :Save, :type => "void ()"
    publish :function => :GetDateTimeMap, :type => "map ()"
    publish :function => :CheckTime, :type => "boolean (string, string, string)"
    publish :function => :CheckDate, :type => "boolean (string, string, string)"
    publish :function => :utc_only, :type => "boolean ()"
    publish :function => :PushVal, :type => "void ()"
    publish :function => :PopVal, :type => "void ()"
    publish :function => :Modified, :type => "boolean ()"
    publish :function => :Import, :type => "boolean (map)"
    publish :function => :Export, :type => "map ()"
    publish :function => :Summary, :type => "string ()"

  protected

    # Whether the architecture of the system is supported by MS Windows
    #
    # @return [Boolean]
    def windows_architecture?
      Arch.x86_64 || Arch.i386
    end

    def disk_analyzer
      Y2Storage::StorageManager.instance.probed_disk_analyzer
    end
  end

  Timezone = TimezoneClass.new
  Timezone.main
end

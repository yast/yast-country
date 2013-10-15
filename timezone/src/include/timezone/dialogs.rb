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

# File:
#	timezone/dialogs.ycp
#
# Authors:
#	Klaus   Kämpf <kkaempf@suse.de>
#	Michael Hager <mike@suse.de>
#	Stefan  Hundhammer <sh@suse.de>
#	Jiri Suchomel <jsuchome@suse.cz>
#
# Summary:
#	Dialogs for timeone and time configuration.
#
# $Id$
module Yast
  module TimezoneDialogsInclude
    def initialize_timezone_dialogs(include_target)
      Yast.import "UI"
      textdomain "country"

      Yast.import "Arch"
      Yast.import "Directory"
      Yast.import "GetInstArgs"
      Yast.import "Label"
      Yast.import "Language"
      Yast.import "Mode"
      Yast.import "NetworkService"
      Yast.import "Package"
      Yast.import "Popup"
      Yast.import "ProductFeatures"
      Yast.import "Service"
      Yast.import "Stage"
      Yast.import "Timezone"
      Yast.import "Wizard"

      @hwclock_s = @hwclock_s_initial = :none

      # if system clock is configured to sync with NTP
      @ntp_used = false

      # ntp server configured to sync with
      @ntp_server = ""

      # if packages for NTP configuration are installed
      @ntp_installed = false

      # when checking for NTP status for first time, check the service status
      @ntp_first_time = true
    end

    # helper function for seting the time related stuff in module and possibly
    # adapting current time according to it
    def SetTimezone(hwclock, timezone, really, changed_time)
      Builtins.y2milestone(
        "SetTimezone hw %1, tz %2 really %3 tchanged %4 initial:%5",
        hwclock,
        timezone,
        really,
        changed_time,
        @hwclock_s_initial
      )

      # simulate the time change
      if !really && hwclock != @hwclock_s_initial
        Timezone.diff = hwclock == :hwclock_utc ? 1 : -1
      else
        Timezone.diff = 0
      end

      Builtins.y2milestone("SetTimezone diff %1", Timezone.diff)

      Timezone.hwclock = hwclock == :hwclock_utc ? "-u" : "--localtime"
      Timezone.Set(timezone, really)

      # Redisplay date/time.
      #
      UI.ChangeWidget(Id(:date), :Value, Timezone.GetDateTime(really, false))

      nil
    end


    # handles the complication that the package yast2-ntp-client may not be present
    def ntp_call(acall, args)
      args = deep_copy(args)
      if !@ntp_installed
        # replace "replace_point" by the widgets
        if acall == "ui_init"
          return false # deselect the RB
        # the help text
        elsif acall == "ui_help_text"
          return "" # or say "will install"? TODO recompute help text
        # save settings, return false if dialog should not exit
        elsif acall == "ui_try_save"
          return true # success, exit loop
        # Service::Enabled. FIXME too smart?
        elsif acall == "GetNTPEnabled"
          return false
        end

        # default: do nothing
        return nil 
        #   other API for completeness:
        # // before UserInput
        # else if (acall == "ui_enable_disable_widgets")
        # else if (acall == "SetUseNTP")
        # else if (acall == "Write")
      end

      ret = WFM.CallFunction("ntp-client_proposal", [acall, args])
      deep_copy(ret)
    end

    # Dialog for setinge system date and time
    # @return true if user changed the time (dialog accepted)
    def SetTimeDialog
      ntp_help_text = Convert.to_string(ntp_call("ui_help_text", {}))

      utc_only = Timezone.utc_only
      textmode = Language.GetTextMode

      # help text for set time dialog
      htext = Ops.add(
        _(
          "<p>The current system time and date are displayed. If required, change them to the correct values manually or use Network Time Protocol (NTP).</p>"
        ) +
          # help text, cont.
          _("<p>Press <b>Accept</b> to save your changes.</p>"),
        ntp_help_text
      )

      if !utc_only
        # help for time calculation basis:
        # hardware clock references local time or UTC?
        htext = htext + _(
            "<p>\n" +
              "Specify whether your machine is set to local time or UTC in <b>Hardware Clock Set To</b>.\n" +
              "Most PCs that also have other operating systems installed (such as Microsoft\n" +
              "Windows) use local time.\n" +
              "Machines that have only Linux installed are usually\n" +
              "set to Universal Time Coordinated (UTC).\n" +
              "If the hardware clock is set to UTC, your system can switch from standard time\n" +
              "to daylight saving time and back automatically.\n" +
              "</p>\n"
        )

        # help text: extra note about localtim
        htext = htext + _(
            "<p>\n" +
              "Note: The internal system clock as used by the Linux kernel must\n" +
              "always be in UTC, because this is the reference for the correct localtime\n" +
              "in user space. If you are choosing localtime for CMOS clock,\n" +
              "check the user manual for background information about side effects.\n" +
              "</p>"
        )
      end

      dt_widgets = false

      hour = ""
      minute = ""
      second = ""
      day = ""
      month = ""
      year = ""

      # check current time and show it in the time widgets
      show_current_time = lambda do
        val = Timezone.GetDateTimeMap
        hour = Ops.get_string(val, "hour", "")
        minute = Ops.get_string(val, "minute", "")
        second = Ops.get_string(val, "second", "")
        day = Ops.get_string(val, "day", "")
        month = Ops.get_string(val, "month", "")
        year = Ops.get_string(val, "year", "")

        if dt_widgets
          UI.ChangeWidget(
            Id(:date),
            :Value,
            Builtins.sformat("%1-%2-%3", year, month, day)
          )
          UI.ChangeWidget(
            Id(:time),
            :Value,
            Builtins.sformat("%1:%2:%3", hour, minute, second)
          )
        else
          UI.ChangeWidget(Id(:hour), :Value, hour)
          UI.ChangeWidget(Id(:minute), :Value, minute)
          UI.ChangeWidget(Id(:second), :Value, second)
          UI.ChangeWidget(Id(:day), :Value, day)
          UI.ChangeWidget(Id(:month), :Value, month)
          UI.ChangeWidget(Id(:year), :Value, year)
        end

        nil
      end

      enable_disable_time_widgets = lambda do |enable|
        UI.ChangeWidget(Id(:change_now), :Enabled, enable)

        enable = enable &&
          Convert.to_boolean(UI.QueryWidget(Id(:change_now), :Value))

        if dt_widgets
          UI.ChangeWidget(Id(:date), :Enabled, enable)
          UI.ChangeWidget(Id(:time), :Enabled, enable)
        else
          UI.ChangeWidget(Id(:hour), :Enabled, enable)
          UI.ChangeWidget(Id(:minute), :Enabled, enable)
          UI.ChangeWidget(Id(:second), :Enabled, enable)
          UI.ChangeWidget(Id(:day), :Enabled, enable)
          UI.ChangeWidget(Id(:month), :Enabled, enable)
          UI.ChangeWidget(Id(:year), :Enabled, enable)
        end

        nil
      end

      dateterm = VBox(
        HBox(
          HSpacing(1),
          # label text, do not change "DD-MM-YYYY"
          Left(Label(_("Current Date in DD-MM-YYYY Format")))
        ),
        HBox(
          HSpacing(10),
          InputField(Id(:day), Opt(:shrinkable), ""),
          HSpacing(),
          InputField(Id(:month), Opt(:shrinkable), ""),
          HSpacing(),
          InputField(Id(:year), Opt(:shrinkable), ""),
          HSpacing(30)
        )
      )
      timeterm = VBox(
        HBox(
          HSpacing(1),
          # label text, do not change "HH:MM:SS"
          Left(Label(_("Current Time in HH:MM:SS Format")))
        ),
        HBox(
          HSpacing(10),
          InputField(Id(:hour), Opt(:shrinkable), ""),
          HSpacing(),
          InputField(Id(:minute), Opt(:shrinkable), ""),
          HSpacing(),
          InputField(Id(:second), Opt(:shrinkable), ""),
          HSpacing(30)
        )
      )
      if UI.HasSpecialWidget(:DateField) && UI.HasSpecialWidget(:TimeField)
        dateterm = HBox(
          # label text
          DateField(Id(:date), _("Current Date"), "")
        )
        timeterm = HBox(
          # label text
          TimeField(Id(:time), _("Current Time"), "")
        )
        dt_widgets = true
      end

      hwclock_term = VBox(
        CheckBox(
          Id(:hwclock),
          Opt(:hstretch, :notify),
          # check box label
          _("&Hardware Clock Set to UTC"),
          @hwclock_s == :hwclock_utc
        ),
        textmode ? Label("") : Empty()
      )

      cont = VBox(
          HBox(
          HWeight(1, VBox()),
          HWeight(
            6,
            RadioButtonGroup(
              Id(:rb),
              VBox(
                # radio button label (= how to setup time)
                Left(RadioButton(Id(:manual), Opt(:notify), _("Manually"))),
                VSpacing(0.5),
                HBox(
                  HSpacing(3),
                  VBox(
                    Left(timeterm),
                    VSpacing(),
                    Left(dateterm),
                    VSpacing(),
                    HBox(
                      HSpacing(0.5),
                      Left(
                        # check box label
                        CheckBox(
                          Id(:change_now),
                          Opt(:notify),
                          _("Change the Time Now"),
                          true
                        )
                      )
                    )
                  )
                ),
                VSpacing(1),
                Left(
                  RadioButton(
                    Id(:ntp),
                    Opt(:notify),
                    # radio button label
                    _("Synchronize with NTP Server"),
                    false
                  )
                ),
                ReplacePoint(Id(:rp), Empty())
              )
            )
          ),
          HWeight(1, VBox())
        ),
        VSpacing(2),
        HBox(
          HWeight(1, VBox()),
          HWeight(6, utc_only ? Empty() : hwclock_term),
          HWeight(1, VBox())
        )
      )

      Wizard.OpenAcceptDialog
      # TODO replace help text after ntp_installed, is.
      Wizard.SetContents(_("Change Date and Time"), cont, htext, true, true)

      Wizard.SetDesktopTitleAndIcon("timezone") if Mode.normal

      show_current_time.call

      ntp_rb = false
      ntp_rb = Convert.to_boolean(
        ntp_call(
          "ui_init",
          {
            "replace_point" => Id(:rp),
            "country"       => Language.GetLanguageCountry,
            "first_time"    => @ntp_first_time
          }
        )
      )
      @ntp_first_time = false
      UI.ChangeWidget(Id(:rb), :CurrentButton, ntp_rb ? :ntp : :manual)

      if !dt_widgets
        Builtins.foreach([:hour, :minute, :second, :day, :month, :year]) do |widget|
          UI.ChangeWidget(Id(widget), :ValidChars, "0123456789")
          UI.ChangeWidget(Id(widget), :InputMaxLength, widget == :year ? 4 : 2)
        end
      end

      ret = nil
      begin
        ntp_call("ui_enable_disable_widgets", { "enabled" => ntp_rb })
        enable_disable_time_widgets.call(!ntp_rb)

        ret = UI.UserInput
        Builtins.y2debug("UserInput ret:%1", ret)

        ntp_handled = Convert.to_symbol(ntp_call("ui_handle", { "ui" => ret }))
        ret = ntp_handled if ntp_handled != nil
        show_current_time.call if ret == :redraw

        if ret == :ntp || ret == :manual
          ntp_rb = ret == :ntp
          # need to install it first?
          if ntp_rb && !Stage.initial && !@ntp_installed
            @ntp_installed = Package.InstallAll(["yast2-ntp-client", "ntp"])
            # succeeded? create UI, otherwise revert the click
            if !@ntp_installed
              ntp_rb = false
              UI.ChangeWidget(Id(:rb), :CurrentButton, :manual)
            else
              # ignore retval, user clicked to use ntp
              ntp_call(
                "ui_init",
                {
                  "replace_point" => Id(:rp),
                  "country"       => Language.GetLanguageCountry,
                  "first_time"    => false
                }
              )
            end
          end
        end

        if ret == :accept
          # Get current settings.
          # UTC vs. localtime, only if needed
          #
          @hwclock_s = :hwclock_utc
          if !utc_only
            @hwclock_s = UI.QueryWidget(Id(:hwclock), :Value) ? :hwclock_utc : :hwclock_localtime

            if !Timezone.windows_partition && @hwclock_s == :hwclock_localtime
              # warning popup, in case local time is selected (bnc#732769)
              if !Popup.ContinueCancel(
                  _(
                    "\n" +
                      "You selected local time, but only Linux  seems to be installed on your system.\n" +
                      "In such case, it is strongly recommended to use UTC, and to click Cancel.\n" +
                      "\n" +
                      "If you want to keep local time, you must adjust the CMOS clock twice the year\n" +
                      "because of Day Light Saving switches. If you miss to adjust the clock, backups may fail,\n" +
                      "your mail system may drop mail messages, etc.\n" +
                      "\n" +
                      "If you use UTC, Linux will adjust the time automatically.\n" +
                      "\n" +
                      "Do you want to continue with your selection (local time)?"
                  )
                )
                ret = :not_next
                next
              end
            end
          end
        end

        if ret == :accept && ntp_rb
          # before the sync, save the time zone (bnc#467318)
          Timezone.Set(
            Timezone.timezone,
            Stage.initial && !Mode.live_installation
          )
          # true: go on, exit; false: loop on
          ntp_handled2 = Convert.to_boolean(ntp_call("ui_try_save", {}))
          if !ntp_handled2
            ret = :retry
          else
            # `ntp_address is constructed by ntp-client_proposal.ycp... :-(
            @ntp_server = Convert.to_string(
              UI.QueryWidget(Id(:ntp_address), :Value)
            )
            # after sync, show real time in the widget
            Timezone.diff = 0
          end
        end
        if ret == :accept && !ntp_rb &&
            UI.QueryWidget(Id(:change_now), :Value) == true
          if dt_widgets
            datel = Builtins.splitstring(
              Convert.to_string(UI.QueryWidget(Id(:date), :Value)),
              "-"
            )
            year = Ops.get_string(datel, 0, "")
            month = Ops.get_string(datel, 1, "")
            day = Ops.get_string(datel, 2, "")
            timel = Builtins.splitstring(
              Convert.to_string(UI.QueryWidget(Id(:time), :Value)),
              ":"
            )
            hour = Ops.get_string(timel, 0, "")
            minute = Ops.get_string(timel, 1, "")
            second = Ops.get_string(timel, 2, "")
          else
            hour = Convert.to_string(UI.QueryWidget(Id(:hour), :Value))
            minute = Convert.to_string(UI.QueryWidget(Id(:minute), :Value))
            second = Convert.to_string(UI.QueryWidget(Id(:second), :Value))
            day = Convert.to_string(UI.QueryWidget(Id(:day), :Value))
            month = Convert.to_string(UI.QueryWidget(Id(:month), :Value))
            year = Convert.to_string(UI.QueryWidget(Id(:year), :Value))
          end
          if !Timezone.CheckTime(hour, minute, second)
            tmp = Builtins.sformat("%1:%2:%3", hour, minute, second)
            # popup text, %1 is entered value
            tmp = Builtins.sformat(
              _("Invalid time (HH:MM:SS) %1.\nEnter the correct time.\n"),
              tmp
            )
            Popup.Error(tmp)
            ret = :retry
          elsif !Timezone.CheckDate(day, month, year)
            tmp = Builtins.sformat("%1-%2-%3", day, month, year)
            # popup text, %1 is entered value
            tmp = Builtins.sformat(
              _("Invalid date (DD-MM-YYYY) %1.\nEnter the correct date.\n"),
              tmp
            )
            Popup.Error(tmp)
            ret = :retry
          else
            # in case of local time, we need to call mkinitrd (after setting timezone)
            if Timezone.hwclock == "--localtime" && !Stage.initial
              Timezone.Set(Timezone.timezone, true)
              Timezone.call_mkinitrd = true
            end

            Timezone.SetTime(year, month, day, hour, minute, second)
          end
        end
      end until ret == :accept || ret == :cancel

      if ret == :accept
        # new system time from ntpdate must be saved to hw clock
        Timezone.SystemTime2HWClock if ntp_rb
        # remember ui
        ntp_call("SetUseNTP", { "ntp_used" => ntp_rb })
        @ntp_used = ntp_rb
      end

      Wizard.CloseDialog
      ret == :accept
    end

    # Main dialog for time zone configuration
    # @param [Hash] args arguments passwd from the called (back/next buttons etc.)
    def TimezoneDialog(args)
      args = deep_copy(args)
      first_run = Ops.get_string(args, "first_run", "no") == "yes"
      # inst_timezone as a part of installation sequence
      if first_run && Stage.initial
        Timezone.hwclock = "--localtime" if Timezone.ProposeLocaltime
      end


      # get current timezone and clock setting
      changed_time = false
      timezone = Timezone.timezone
      timezone_old = timezone
      timezone_initial = timezone
      hwclock = Timezone.hwclock

      Builtins.y2milestone("timezone_old %1", timezone_old)

      timezone = Timezone.UpdateTimezone(timezone)

      # Initially set the current timezone to establish a consistent state.
      sel = Timezone.Set(timezone, Stage.initial && !Mode.live_installation)

      utc_only = Timezone.utc_only
      Builtins.y2milestone("utc_only %1", utc_only)

      Timezone.PushVal


      settime = Empty()

      # "On a mainframe it is impossible for the user to change the hardware clock.
      # So you can only specify the timezone." (ihno)
      if !Arch.s390 && !Mode.config
        # button text
        settime = PushButton(Id(:settime), _("Other &Settings..."))
      end

      textmode = Language.GetTextMode

      timezone_selector = false

      zonemap = Timezone.get_zonemap

      # map of zones conversions
      yast2zonetab = deep_copy(Timezone.yast2zonetab)

      # map of timezone -> translated label to be passed to TimezoneSelector
      zones = {}

      # cache the zonemap with the order sorted according to current locale
      sorted_zonemap = {}

      Builtins.foreach(zonemap) do |region|
        Builtins.foreach(Ops.get_map(region, "entries", {})) do |key, name|
          if !Builtins.haskey(yast2zonetab, key)
            Ops.set(zones, Ops.get(yast2zonetab, key, key), name)
          end
        end
      end

      @ntp_installed = Stage.initial || Package.Installed("yast2-ntp-client")


      # read NTP status
      if first_run && NetworkService.isNetworkRunning && !Mode.live_installation &&
          !GetInstArgs.going_back &&
          ProductFeatures.GetBooleanFeature("globals", "default_ntp_setup") == true
        # true by default (fate#303520)
        @ntp_used = true
        # configure NTP client
        Builtins.srandom
        @ntp_server = Builtins.sformat(
          "%1.opensuse.pool.ntp.org",
          Builtins.random(4)
        )
        argmap = {
          "server"       => @ntp_server,
          # FIXME ntp-client_proposal doesn't understand 'servers' yet
          "servers"      => [
            "0.opensuse.pool.ntp.org",
            "1.opensuse.pool.ntp.org",
            "2.opensuse.pool.ntp.org",
            "3.opensuse.pool.ntp.org"
          ],
          "ntpdate_only" => true
        }
        rv = Convert.to_symbol(ntp_call("Write", argmap))
        if rv == :invalid_hostname
          Builtins.y2warning("Invalid NTP server hostname %1", @ntp_server)
          @ntp_used = false
        else
          Timezone.SystemTime2HWClock
          Builtins.y2milestone("proposing NTP server %1", @ntp_server)
          ntp_call("SetUseNTP", { "ntp_used" => @ntp_used })
        end
      elsif Stage.initial
        # from installation summaru
        @ntp_used = Timezone.ntp_used
      elsif @ntp_installed
        @ntp_used = Convert.to_boolean(ntp_call("GetNTPEnabled", {}))
        @ntp_used = @ntp_used == true # nil->false, just in case of parse error
      end

      time_frame_label =
        # frame label
        @ntp_used ?
          _("Date and Time (NTP is configured)") :
          # frame label
          _("Date and Time")

      # Read system date and time.
      date = Timezone.GetDateTime(true, false)

      timezoneterm = HBox()

      if UI.HasSpecialWidget(:TimezoneSelector) == true
        timezone_selector = true
        worldmap = Ops.add(Directory.themedir, "/current/worldmap/worldmap.jpg")
        timezoneterm = VBox(
          TimezoneSelector(Id(:timezonemap), Opt(:notify), worldmap, zones),
          HBox(
            HWeight(
              1,
              ComboBox(
                Id(:region),
                Opt(:notify),
                # label text
                _("&Region"),
                Timezone.Region
              )
            ),
            HSpacing(),
            HWeight(
              1,
              ReplacePoint(
                Id(:tzsel),
                # title for combo box 'timezone'
                ComboBox(Id(:timezone), Opt(:notify), _("Time &Zone"))
              )
            ),
            HSpacing(),
            HWeight(1, VBox(
              Label(_("Date and Time")),
              Label(Id(:date), date))
            ),
            HSpacing(),
            VBox(
              Label(" "),
              settime
            )
          )
        )
      else
        timezoneterm = VBox(
          HBox(
            SelectionBox(
              Id(:region),
              Opt(:notify, :immediate),
              # label text
              _("&Region"),
              Timezone.Region
            ),
            HSpacing(),
            ReplacePoint(
              Id(:tzsel),
              # title for selection box 'timezone'
              SelectionBox(Id(:timezone), Opt(:notify), _("Time &Zone"))
            )
          ),
          HBox(
            HSpacing(),
            VBox(
              Left(Label(_("Date and Time"))),
              Left(Label(Id(:date), date))
            ),
            HSpacing(),
            VBox(
              Label(" "),
              settime
            ),
            HSpacing()
          )
        )
      end

      contents = MarginBox(
        term(:leftMargin, 2),
        term(:rightMargin, 2),
        term(:topMargin, 0),
        term(:bottomMargin, 0.2),
        timezoneterm
      )
      # cache for lists with timezone items
      timezones_for_region = {}
      get_timezones_for_region = lambda do |region, zone|
        if !Builtins.haskey(sorted_zonemap, region)
          reg_list = Builtins.maplist(
            Ops.get_map(zonemap, [region, "entries"], {})
          ) { |key, name| [name, key] }

          reg_list = Builtins.sort(
            Convert.convert(reg_list, :from => "list", :to => "list <list>")
          ) do |a, b|
            # bnc#385172: must use < instead of <=, the following means:
            # strcoll(x) <= strcoll(y) && strcoll(x) != strcoll(y)
            lsorted = Builtins.lsort(
              [Ops.get_string(a, 0, ""), Ops.get_string(b, 0, "")]
            )
            lsorted_r = Builtins.lsort(
              [Ops.get_string(b, 0, ""), Ops.get_string(a, 0, "")]
            )
            Ops.get_string(lsorted, 0, "") == Ops.get_string(a, 0, "") &&
              lsorted == lsorted_r
          end
          Ops.set(sorted_zonemap, region, reg_list)
        end
        Builtins.maplist(Ops.get_list(sorted_zonemap, region, [])) do |entry|
          Item(
            Id(Ops.get_string(entry, 1, "")),
            Ops.get_string(entry, 0, ""),
            Ops.get_string(entry, 1, "") == zone
          )
        end
      end
      # region was seleced: show the correct list of timezones
      show_selected_region = lambda do |sel2, zone|
        if timezone_selector
          UI.ChangeWidget(Id(:region), :Value, sel2)
        else
          UI.ChangeWidget(Id(:region), :CurrentItem, sel2)
        end

        UI.ReplaceWidget(
          Id(:tzsel),
          timezone_selector ?
            ComboBox(
              Id(:timezone),
              Opt(:notify),
              # label text
              _("Time &Zone"),
              get_timezones_for_region.call(sel2, zone)
            ) :
            SelectionBox(
              Id(:timezone),
              Opt(:notify),
              # label text
              _("Time &Zone"),
              get_timezones_for_region.call(sel2, zone)
            )
        )

        nil
      end
      # which region is selected?
      selected_region = lambda do
        timezone_selector ?
          Convert.to_integer(UI.QueryWidget(Id(:region), :Value)) :
          Convert.to_integer(UI.QueryWidget(Id(:region), :CurrentItem))
      end
      # which timezone is selected?
      selected_timezone = lambda do
        timezone_selector ?
          Convert.to_string(UI.QueryWidget(Id(:timezone), :Value)) :
          Convert.to_string(UI.QueryWidget(Id(:timezone), :CurrentItem))
      end

      # for given timezone (selected in map), find out to which region it belongs
      get_region_for_timezone = lambda do |current, zone|
        # first check if it is not in current region
        if Builtins.haskey(Ops.get_map(zonemap, [current, "entries"], {}), zone)
          return current
        end
        reg = 0
        Builtins.foreach(zonemap) do |region|
          if Builtins.haskey(Ops.get_map(region, "entries", {}), zone)
            raise Break
          end
          reg = Ops.add(reg, 1)
        end
        reg
      end

      # help for timezone screen
      help_text = _("\n<p><b><big>Time Zone and Clock Settings</big></b></p>") +
        # help for timezone screen
        _(
          "<p>\n" +
            "To select the time zone to use in your system, first select the <b>Region</b>.\n" +
            "In <b>Time Zone</b>, then select the appropriate time zone, country, or \n" +
            "region from those available.\n" +
            "</p>\n"
        )



      if !Arch.s390 && !Mode.config
        # general help trailer
        help_text = Ops.add(
          help_text,
          _(
            "<p>\n" +
              "If the current time is not correct, use <b>Change</b> to adjust it.\n" +
              "</p>"
          )
        )
      end

      # Screen title for timezone screen
      Wizard.SetContents(
        _("Clock and Time Zone"),
        contents,
        help_text,
        Ops.get_boolean(args, "enable_back", true),
        Ops.get_boolean(args, "enable_next", true)
      )

      if Stage.initial || Stage.firstboot
        Wizard.SetTitleIcon("yast-timezone")
      else
        Wizard.SetDesktopTitleAndIcon("timezone")
      end

      @hwclock_s = hwclock == "-u" ? :hwclock_utc : :hwclock_localtime
      hwclock_s_old = @hwclock_s
      @hwclock_s_initial = @hwclock_s

      show_selected_region.call(sel, timezone)
      if timezone_selector
        UI.ChangeWidget(
          Id(:timezonemap),
          :CurrentItem,
          Ops.get(yast2zonetab, timezone, timezone)
        )
      end

      UI.SetFocus(Id(:region))

      ret = nil
      begin
        ret = Convert.to_symbol(Wizard.UserInput)

        Builtins.y2debug("ret %1", ret)

        ret = :next if ret == :ok

        break if !Mode.config && ret == :abort && Popup.ConfirmAbort(:painless)
        if ret == :region
          num = selected_region.call
          next if num == sel
          show_selected_region.call(num, "")
          tz = selected_timezone.call
          if tz != timezone
            timezone = tz
            changed_time = true if timezone != timezone_old
            timezone_old = timezone
            SetTimezone(@hwclock_s, timezone, false, changed_time)
          end
          if timezone_selector
            UI.ChangeWidget(Id(:timezonemap), :CurrentItem, timezone)
          end
          sel = num
        elsif ret == :settime
          # timezone was not adapted in ncurses (bnc#617861)
          if textmode
            tz = selected_timezone.call
            if tz != timezone
              timezone = tz
              changed_time = true if timezone != timezone_old
              timezone_old = timezone
              SetTimezone(@hwclock_s, timezone, false, changed_time)
            end
          end
          if SetTimeDialog()
            Timezone.diff = 0
            UI.ChangeWidget(
              Id(:date),
              :Value,
              Timezone.GetDateTime(false, false)
            )
            changed_time = true
            # adapt frame label, NTP status may be changed
            time_frame_label =
              # frame label
              @ntp_used ?
                _("Date and Time (NTP is configured)") :
                # frame label
                _("Date and Time")
            UI.ChangeWidget(Id(:time_fr), :Label, time_frame_label)
          end
        elsif ret == :next || ret == :timezone || ret == :timezonemap ||
            ret == :hwclock
          if ret == :timezonemap
            timezone = Convert.to_string(
              UI.QueryWidget(Id(:timezonemap), :Value)
            )

            reg = get_region_for_timezone.call(sel, timezone)
            if reg == sel
              UI.ChangeWidget(Id(:timezone), :Value, timezone)
            else
              sel = reg
              show_selected_region.call(sel, timezone)
            end
          else
            timezone = selected_timezone.call
          end
          if ret == :timezone
            sel = selected_region.call
            if timezone_selector
              UI.ChangeWidget(
                Id(:timezonemap),
                :Value,
                Ops.get(yast2zonetab, timezone, timezone)
              )
            end
          end

          if timezone == nil || Builtins.size(timezone) == 0
            # popup text
            Popup.Error(_("Select a valid time zone."))
            ret = :again
            timezone = timezone_old
          end
          Builtins.y2milestone("timezone %1 ret %2", timezone, ret)

          if timezone != timezone_old || @hwclock_s != hwclock_s_old ||
              ret == :next
            changed_time = true if timezone != timezone_old
            timezone_old = timezone
            hwclock_s_old = @hwclock_s
            SetTimezone(@hwclock_s, timezone, ret == :next, changed_time)
          end

          if ret == :next
            # User wants to keep his changes.
            # Set user_decision flag in timezone module.
            #
            Timezone.user_decision = true
            Timezone.user_hwclock = true
            Timezone.ntp_used = @ntp_used
            # See bnc#638185c5: refresh_initrd should be called if HWCLOCK is changed (--localtime <-> --utc) and/or
            # if --localtime is set and TIMEZONE will be changed.
            if @hwclock_s != @hwclock_s_initial ||
                @hwclock_s == :hwclock_localtime && timezone != timezone_initial
              Timezone.call_mkinitrd = true
            end

            if @ntp_used && @ntp_server != ""
              # save NTP client settings now
              ntp_call(
                "Write",
                { "server" => @ntp_server, "write_only" => true }
              )
            end
          end
        end
      end until ret == :next || ret == :back || ret == :cancel

      Timezone.PopVal if ret != :next
      ret
    end
  end
end

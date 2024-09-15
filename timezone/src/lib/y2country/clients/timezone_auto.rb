require "yast"
require "installation/auto_client"

Yast.import "Mode"
Yast.import "Timezone"
Yast.import "UI"
Yast.import "AutoInstall"
Yast.import "Wizard"

module Yast
  class TimezoneAutoClient < ::Installation::AutoClient
    include Yast::Logger

    def initialize
      Yast.include self, "timezone/dialogs.rb"
      super
    end

    def change
      Wizard.CreateDialog
      Wizard.HideAbortButton
      ret = TimezoneDialog({ "enable_back" => true, "enable_next" => true })
      Wizard.CloseDialog
      ret
    end

    def import(data)
      result = Timezone.Import(data)
      fix_obsolete_timezones
      result
    end

    def summary
      Timezone.Summary
    end

    def reset
      Timezone.PopVal
      Timezone.modified = false
      {}
    end

    def read
      Timezone.Read
    end

    def export
      Timezone.Export
    end

    def write
      Timezone.Save
    end

    def modified?
      Timezone.Modified
    end

    def packages
      {}
    end

    def modified
      Timezone.modified = true
    end

    def fix_obsolete_timezones
      old_timezone = Timezone.timezone
      new_timezone = Timezone.UpdateTimezone(old_timezone)
      return if new_timezone == old_timezone

      Timezone.Set(new_timezone, true)
      Timezone.modified = true
      log.info("Changed obsolete timezone #{old_timezone} to #{new_timezone}")
      nil
    end
  end
end

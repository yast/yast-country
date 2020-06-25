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

    def change
      Yast.include self, "timezone/dialogs.rb"

      Wizard.CreateDialog
      Wizard.HideAbortButton
      ret = TimezoneDialog({ "enable_back" => true, "enable_next" => true })
      Wizard.CloseDialog
      ret
    end

    def import(data)
      Timezone.Import(data)
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
      ret = Timezone.Export
      if Mode.autoyast_clone_system
        # Called by -yast clone_system; NOT in AY configuration module
        if(Timezone.ProposeLocaltime() &&
           ret["hwclock"] == "localtime") ||
          (!Timezone.ProposeLocaltime() &&
           ret["hwclock"] == "UTC")
          log.info("hwclock <#{ret["hwclock"]}> is the default value"\
                   " --> do not export it")
          ret.delete("hwclock")
        end
        
        local_timezone = Timezone.GetTimezoneForLanguage(
          Language.language,
          "US/Eastern"
        )
        if local_timezone == ret["timezone"]
          log.info("timezone <#{ret["timezone"]}> is the default value"\
                   " --> no export")
          ret.delete("timezone")
        end
      end
      ret
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
  end
end

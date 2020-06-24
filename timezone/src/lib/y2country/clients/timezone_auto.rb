require "yast"
require "installation/auto_client"

Yast.import "Mode"
Yast.import "Timezone"
Yast.import "UI"

module Yast
  class TimezoneAutoClient ::Installation::AutoClient

    include Yast::Logger

    def run
      textdomain "timezone"
      Yast.include self, "timezone/dialogs.rb"

      progress_orig = Progress.set(false)
      ret = super
      Progress.set(progress_orig)
      ret
    end
    
    def change
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
      if !Mode.config
        # normal installation; NOT in AY configuration module
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
                   " --> do not export it")
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

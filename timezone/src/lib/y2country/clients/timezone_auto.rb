require "yast"
require "installation/auto_client"

Yast.import "Mode"
Yast.import "Timezone"
Yast.import "UI"

module Yast
  class TimezoneAutoClient ::Installation::AutoClient
    Yast.include self, "timezone/dialogs.rb"
    
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
          ret.delete("hwclock")          
        end
        
        local_timezone = Timezone.GetTimezoneForLanguage(
          Language.language,
          "US/Eastern"
        )
        ret.delete("timezone") if local_timezone == ret["timezone"]
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

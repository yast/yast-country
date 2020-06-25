require "yast"
require "installation/auto_client"

Yast.import "Language"
Yast.import "Console"
Yast.import "AutoInstall"
Yast.import "Wizard"
Yast.import "Mode"

module Language
  class AutoClient < ::Installation::AutoClient

    include Yast::Logger
    
    def change
      Wizard.CreateDialog
      Wizard.HideAbortButton

      ret = WFM.CallFunction(
        "select_language",
        [{ "enable_back" => true, "enable_next" => true }]
      )
      Wizard.CloseDialog
      ret
    end
    
    def import(data)
      Language.Import(data)      
    end
    
    def summary
      Language.Summary
    end
    
    def reset
      Language.Import(
        {
          "language"  => Language.language_on_entry,
          "languages" => Language.languages_on_entry
        }
      )
      Language.ExpertSettingsChanged = false
      {}      
    end

    def read
      Language.Read(true)
    end
    
    def export
      Language.Export
    end
    
    def write
      Console.SelectFont(Language.language)
      Console.Save
      Language.Save      
    end
    
    def modified?
      Language.Modified
    end

    def packages
      {}
    end
    
    def modified
      Language.ExpertSettingsChanged = true # hook (no general 'modified' variable)
    end
  end
end

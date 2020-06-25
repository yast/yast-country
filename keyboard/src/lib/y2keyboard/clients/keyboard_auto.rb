require "yast"
require "installation/auto_client"

Yast.import "Keyboard"
Yast.import "AutoInstall"
Yast.import "Wizard"
Yast.import "Arch"
Yast.import "Mode"
Yast.import "Language"

module Keyboard
  class AutoClient < ::Installation::AutoClient

    include Yast::Logger
    
    def change
      ret = true
      if !Arch.s390
        Wizard.CreateDialog
        Wizard.HideAbortButton
        ret = WFM.CallFunction("keyboard")
        Wizard.CloseDialog
      end
      ret
    end
    
    def import(data)
      Keyboard.Import(data)
    end
    
    def summary
      Keyboard.Summary
    end
    
    def reset
      Keyboard.Import({"keymap" => Keyboard.keyboard_on_entry })
    end

    def read
      Keyboard.Read
    end
    
    def export
      Keyboard.Export
    end
    
    def write
      Keyboard.Save
    end
    
    def modified?
      Keyboard.Modified
    end
    
    def modified
      Keyboard.SetModified
    end

    def packages
      {}
    end
  end
end

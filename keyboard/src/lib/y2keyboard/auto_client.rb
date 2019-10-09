require "yast"
require "installation/auto_client"

Yast.import "Keyboard"
Yast.import "AutoInstall"
Yast.import "Wizard"
Yast.import "Arch"

module Keyboard
  class AutoClient < ::Installation::AutoClient
    Yast.include self, "keyboard/dialogs.rb"
    
    def change
      ret = true
      if !Arch.s390
        Wizard.CreateDialog
        Wizard.HideAbortButton
        ret = KeyboardDialog({})
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
  end
end

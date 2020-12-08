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
  end
end

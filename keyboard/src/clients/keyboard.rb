require "yast"
require_relative "../lib/y2keyboard/clients/keyboard"

module Yast
  class KeyboardClient < Client
    def main
      textdomain "country"

      Yast.import "Arch"
      Yast.import "CommandLine"
      Yast.import "Keyboard"

      # The command line description map
      @cmdline = {
        "id"         => "keyboard",
        # TRANSLATORS: command line help text for Securoty module
        "help"       => _("Keyboard configuration."),
        "guihandler" => fun_ref(method(:KeyboardSequence), "any ()"),
        "initialize" => fun_ref(method(:KeyboardRead), "boolean ()"),
        "finish"     => fun_ref(method(:KeyboardWrite), "boolean ()"),
        "actions"    => {
          "summary" => {
            "handler"  => fun_ref(
              method(:KeyboardSummaryHandler),
              "boolean (map)"
            ),
            # command line help text for 'summary' action
            "help"     => _("Keyboard configuration summary."),
            "readonly" => true
          },
          "set"     => {
            "handler" => fun_ref(method(:KeyboardSetHandler), "boolean (map)"),
            # command line help text for 'set' action
            "help"    => _("Set new values for keyboard configuration.")
          },
          "list"    => {
            "handler"  => fun_ref(method(:KeyboardListHandler), "boolean (map)"),
            # command line help text for 'list' action
            "help"     => _("List all available keyboard layouts."),
            "readonly" => true
          }
        },
        "options"    => {
          "layout" => {
            # command line help text for 'set layout' option
            "help" => _("New keyboard layout"),
            "type" => "string"
          }
        },
        "mappings"   => { "summary" => [], "set" => ["layout"], "list" => [] }
      }

      CommandLine.Run(@cmdline)
    end

    # read keyboard settings
    def KeyboardRead
      Keyboard.Read
      true
    end

    # write keyboard settings
    def KeyboardWrite
      Keyboard.Save
      true
    end

    # the keyboard configuration sequence
    def KeyboardSequence
      # dont ask for keyboard on S/390
      return :next if Arch.s390

      Y2Keyboard::Clients::Keyboard.run
    end

    # Handler for keyboard summary
    def KeyboardSummaryHandler(options)
      # summary label
      CommandLine.Print(_("Current Keyboard Layout: %s" % Keyboard.current_kbd))
      true
    end

    # Handler for listing keyboard layouts
    def KeyboardListHandler(options)
      Keyboard.Selection.each do |code, name|
        CommandLine.Print(Builtins.sformat("%1 (%2)", code, name))
      end
      true
    end

    # Handler for changing keyboard settings
    def KeyboardSetHandler(options)
      keyboard = options["layout"] || ""

      if keyboard == "" || !Keyboard.Selection.key?(keyboard)
        # TRANSLATORS: error message (%1 is given layout); do not translate 'list'
        CommandLine.Print(
          _("Keyboard layout '%s' is invalid. Use a 'list' command to see possible values." % keyboard)
        )
        false
      else
        Keyboard.Set(keyboard)
        Keyboard.Modified
        true
      end
    end
  end
end

Yast::KeyboardClient.new.main

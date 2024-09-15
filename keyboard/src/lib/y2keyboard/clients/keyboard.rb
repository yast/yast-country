require "yast"

require_relative "../dialogs/layout_selector"
require_relative "../strategies/systemd_strategy"
require_relative "../strategies/yast_proposal_strategy"
require_relative "../keyboard_layout"
require "y2keyboard/keyboards"

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

      Yast::KeyboardClient.setup
    end

    # Handler for keyboard summary
    def KeyboardSummaryHandler(_options)
      # summary label
      CommandLine.Print(format(_("Current Keyboard Layout: %s"), Keyboard.current_kbd))
      true
    end

    # Handler for listing keyboard layouts
    def KeyboardListHandler(_options)
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
          format(_("Keyboard layout '%s' is invalid. Use a 'list' command to see possible values."), keyboard)
        )
        false
      else
        Keyboard.Set(keyboard)
        Keyboard.Modified
        true
      end
    end

    def self.setup
      Yast.import "Stage"
      Yast.import "Mode"

      strategy = if Yast::Stage.initial || Yast::Mode.config
        # In installation mode or AY configuration mode
        Y2Keyboard::Strategies::YastProposalStrategy.new
      else
        # running system --> using systemd
        Y2Keyboard::Strategies::SystemdStrategy.new
      end
      Y2Keyboard::KeyboardLayout.use(strategy, Keyboards.all_keyboards)
      Y2Keyboard::Dialogs::LayoutSelector.new.run
    end
  end
end

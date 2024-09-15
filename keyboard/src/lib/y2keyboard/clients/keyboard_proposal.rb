require "installation/proposal_client"

module Yast
  # Proposal for keyboard settings
  class KeyboardProposalClient < ::Installation::ProposalClient
    include Yast::I18n
    include Yast::Logger

    def initialize
      super

      Yast.import "UI"
      Yast.import "Arch"
      Yast.import "Keyboard"
      Yast.import "Wizard"

      textdomain "country"
    end

  protected

    def make_proposal(attrs)
      force_reset = attrs["force_reset"] || false
      language_changed = attrs["language_changed"] || false
      { "raw_proposal"     => [Keyboard.MakeProposal(force_reset, language_changed)],
        "language_changed" => false }
    end

    def ask_user(_param)
      if Arch.s390
        log.info("S390: No keyboard proposal change by the user.")
        return { "workflow_sequence" => :next, "language_changed" => false }
      end

      Keyboard.Read # save the inital values

      argmap = {
        "enable_back" => true,
        "enable_next" => Ops.get_boolean(@param, "has_next", false)
      }
      begin
        Yast::Wizard.OpenAcceptDialog
        result = WFM.CallFunction("keyboard", [argmap])
      ensure
        Yast::Wizard.CloseDialog
      end
      log.info "Returning from keyboard ask_user with #{result}"

      # Fill return map
      { "workflow_sequence" => @result, "language_changed" => false }
    end

    def description
      {
        # summary item
        "rich_text_title" => _("Keyboard Layout"),
        # menue label text
        "menu_title"      => _("&Keyboard Layout"),
        "id"              => "keyboard_stuff"
      }
    end
  end
end

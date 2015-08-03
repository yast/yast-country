
module Yast
  # TODO: separate UI and non-UI, figure out a reasonable UI interface
  # (check also CWM)

  # Acts as interface of the Timezone package to NTP functionality
  class TimezoneNtp
    include Yast::UIShortcuts

    # @return [Boolean] if system clock is configured to sync with NTP
    attr_accessor :used         # (Writing it also notifies NtpClient)

    def used=(value)
      @used = value
      ntp_call("SetUseNTP", { "ntp_used" => value })
    end

    # @return [Boolean] used in the installed system
    def enabled?
      ntp_call("GetNTPEnabled", {}) == true
    end

    # @return [String] ntp server configured to sync with
    attr_accessor :server

    def initialize
      Yast.import "Language"
      Yast.import "Package"
      Yast.import "Stage"

      @used = false
      self.server = ""
      # when checking for NTP status for first time, check the service status
      @first_time = true
      @installed = Stage.initial || Package.Installed("yast2-ntp-client")
    end

    # @return [String] a RichText help
    def help
      ntp_call("ui_help_text", {})
    end

    # Replace the replace_point with our UI, and return whether it should be
    # selected
    # @return [Boolean]
    def ui_init
      ntp_rb = Convert.to_boolean(
        ntp_call(
          "ui_init",
          {
            "replace_point" => Id(:rp),
            "country"       => Language.GetLanguageCountry,
            "first_time"    => @first_time
          }
        )
      )
      @first_time = false
      ntp_rb
    end

    # @param enabled [Boolean]
    def ui_enable_disable_widgets(enabled)
      ntp_call("ui_enable_disable_widgets", { "enabled" => enabled })
    end

    # @return [Symbol,nil]
    def ui_handle(user_input)
      Convert.to_symbol(ntp_call("ui_handle", { "ui" => user_input }))
    end

    # if the responsible yast package is not installed,
    # fall back to disabling the config widgets
    def installed?
      @installed
    end

    # @return [Boolean] false if failed
    def ensure_installed
      # need to install it first?
      if !Stage.initial && !@installed
        @installed = Package.InstallAll(["yast2-ntp-client", "ntp"])
        # succeeded? create UI, otherwise revert the click
        if @installed
          ui_init
        end
        return @installed
      end
      true
    end

    # @return [Boolean] success?
    def ui_try_save
      ret = Convert.to_boolean(ntp_call("ui_try_save", {}))
      if ret
        self.server = UI.QueryWidget(Id(:ntp_address), :Value)
      end
      ret
    end

    # @return [Boolean] success
    def setup_with_opensuse_servers
      @used = true

      # configure NTP client
      Builtins.srandom
      self.server = Builtins.sformat(
          "%1.opensuse.pool.ntp.org",
          Builtins.random(4)
        )
      argmap = {
          "server"       => server,
          "servers"      => [
            "0.opensuse.pool.ntp.org",
            "1.opensuse.pool.ntp.org",
            "2.opensuse.pool.ntp.org",
            "3.opensuse.pool.ntp.org"
          ],
          "ntpdate_only" => true
        }
      rv = Convert.to_symbol(ntp_call("Write", argmap))
      if rv == :invalid_hostname
        Builtins.y2warning("Invalid NTP server hostname %1", server)
        @used = false
      else
        Builtins.y2milestone("proposing NTP server %1", server)
          ntp_call("SetUseNTP", { "ntp_used" => @used })
      end
      @used
    end

    def save
      if used && server != ""
        # save NTP client settings now
        ntp_call("Write", { "server" => server, "write_only" => true })
      end
    end

    private


    # This proxy handles the complication
    # that the package yast2-ntp-client may not be present
    # (on the running system).
    # The called client has been meanwhile moved to this package but it
    # does not check for the dependencies itself yet.
    def ntp_call(acall, args)
      if !@installed
        # replace "replace_point" by the widgets
        if acall == "ui_init"
          return false # deselect the RB
        # the help text
        elsif acall == "ui_help_text"
          return "" # or say "will install"? TODO recompute help text
        # save settings, return false if dialog should not exit
        elsif acall == "ui_try_save"
          return true # success, exit loop
        elsif acall == "GetNTPEnabled"
          return false
        end

        # default: do nothing
        return nil
        #   other API for completeness:
        # // before UserInput
        # else if (acall == "ui_enable_disable_widgets")
        # else if (acall == "SetUseNTP")
        # else if (acall == "Write")
      end

      ret = WFM.CallFunction("timezone_ntp", [acall, args])
      ret
    end
  end
end

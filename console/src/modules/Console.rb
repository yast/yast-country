# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2012 Novell, Inc. All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------

# File:
#	Console.ycp
#
# Module:
#	Console
#
# Depends:
#	Language
#
# Summary:
#	provide console specific stuff (esp. font and encoding)
#<BR>
# sysconfig /etc/sysconfig/console:<BR>
#<UL>
#<LI>	CONSOLE_FONT		string	console font</LI>
#<LI>	CONSOLE_SCREENMAP	string	console screenmap</LI>
#<LI>	CONSOLE_UNICODEMAP	string	console unicode map</LI>
#<LI>	CONSOLE_MAGIC		string	console magic control sequence</LI>
#<LI>	CONSOLE_ENCODING	string	console encoding</LI>
#</UL>
#
# $Id$
#
# Author:
#	Klaus Kaempf <kkaempf@suse.de>
#
require "yast"
require "json"
Yast.import "Directory"

module Yast
  class ConsoleClass < Module
    def main
      Yast.import "UI"

      Yast.import "Kernel"
      Yast.import "Mode"
      Yast.import "Language"
      Yast.import "Linuxrc"
      Yast.import "Encoding"
      Yast.import "Stage"
      Yast.import "OSRelease"

      # current base language, used in Check
      @language = "en_US"

      @font = "lat1-16.psfu"
      @unicodeMap = ""
      @screenMap = ""
      @magic = "(B"

      # non-empty if serial console (written /etc/inittab)
      # -> S0:12345:respawn:/sbin/agetty -L 9600<n8> ttyS0
      # something like "ttyS0,9600" from /etc/install.inf
      @serial = ""

      # Console fonts map (used as cache for #consolefonts)
      @consolefonts = nil

      Console()
    end

    # activate a language specific console font
    #
    # @param	string	language	ISO code of language
    # @return	[String]	encoding	encoding for console i/o

    def SelectFont(lang)
      fqlanguage = Language.GetLocaleString(lang)

      consolefont = consolefonts[fqlanguage] || consolefonts[lang]
      if consolefont.nil? && lang.size > 2
        consolefont = consolefonts[lang[0,2]]
      end
      consolefont ||= []

      if !consolefont.empty?
        @language = lang

        @font = consolefont["font"]
        @unicodeMap = consolefont["unicodeMap"]
        @screenMap = consolefont["screenMap"]
        @magic = consolefont["magic"]

        currentLanguage = WFM.GetLanguage

        # Eventually must switch languages to get correct encoding
        if currentLanguage != @language
          currentEncoding = WFM.GetEncoding # save encoding

          Encoding.console = WFM.SetLanguage(@language) # switch lang, get proposed encoding

          WFM.SetLanguage(currentLanguage, currentEncoding) # reset as it was before
        end

        if Linuxrc.braille
          SCR.Execute(path(".target.bash"), "/usr/bin/setfont")
        elsif !Mode.commandline
          UI.SetConsoleFont(@magic, @font, @screenMap, @unicodeMap, @language)
        end
      end

      Builtins.y2milestone(
        "Language %1 -> Console encoding %2",
        @language,
        Encoding.console
      )
      Encoding.console
    end

    # save data to system (rc.config agent)

    def Save
      # writing vconsole.conf directly, no other API available ATM
      SCR.Write(path(".etc.vconsole_conf.FONT"), @font)
      SCR.Write(path(".etc.vconsole_conf.FONT_MAP"), @screenMap)
      SCR.Write(path(".etc.vconsole_conf.FONT_UNIMAP"), @unicodeMap)
      SCR.Write(path(".etc.vconsole_conf"), nil)

      SCR.Write(path(".sysconfig.console.CONSOLE_MAGIC"), @magic)

      SCR.Write(path(".sysconfig.console.CONSOLE_ENCODING"), WFM.GetEncoding)
      SCR.Write(
        path(".sysconfig.console.CONSOLE_ENCODING.comment"),
        "\n" +
          "# Encoding used for output of non-ascii characters.\n" +
          "#\n"
      )
      SCR.Write(path(".sysconfig.console"), nil)

      if @serial != ""
        # during a fresh install, provide the autoconsole feature
        # it detects wether the kernel console is VGA/framebuffer or serial
        # it also starts agetty with the correct speed (#41623)
        # fresh install, all is easy: just add the getty to /dev/console
        # upgrade: disable old entries for serial console
        SCR.Execute(
          path(".target.bash"),
          "sed -i '/^\\(hvc\\|hvsi\\|S[0-9]\\)/s@^.*@#&@' /etc/inittab"
        )

        # find out if the baud rate is not present on command line (bnc#602743)
        rate = 42
        Builtins.foreach(Builtins.splitstring(Kernel.GetCmdLine, "\t ")) do |part|
          if Builtins.substring(part, 0, 11) == "console=tty" &&
              Builtins.issubstring(part, ",")
            srate = Ops.get(Builtins.splitstring(part, ","), 1, "42")
            rate = Builtins.tointeger(srate) # "bbbbpnf" -> bbbb, where 'b' is number and 'p' character
          end
        end
        rate = 42 if rate == nil
        SCR.Execute(
          path(".target.bash"),
          Builtins.sformat(
            "grep -E '^cons:' /etc/inittab || /bin/echo 'cons:12345:respawn:/sbin/smart_agetty -L %1 console' >> /etc/inittab",
            rate
          )
        )
        SCR.Execute(
          path(".target.bash"),
          "grep -Ew ^console /etc/securetty || /bin/echo console >> /etc/securetty"
        )
      end

      nil
    end

    # restore data to system (rc.config agent)
    # returns encoding
    def Restore
      @font = Misc.SysconfigRead(path(".etc.vconsole_conf.FONT"), "")
      @screenMap = Misc.SysconfigRead(path(".etc.vconsole_conf.FONT_MAP"), "")
      @unicodeMap = Misc.SysconfigRead(path(".etc.vconsole_conf.FONT_UNIMAP"), "")
      Builtins.y2milestone("vconsole.conf: FONT: %1, FONT_MAP: %2, FONT_UNIMAP: %3", @font, @screenMap, @unicodeMap)

      @magic = Convert.to_string(
        SCR.Read(path(".sysconfig.console.CONSOLE_MAGIC"))
      )
      @language = Language.GetCurrentLocaleString
      Builtins.y2milestone("encoding %1", Encoding.console)
      Encoding.console
    end

    # initialize console settings
    def Init
      if Linuxrc.braille
        SCR.Execute(path(".target.bash"), "/usr/bin/setfont")
      else
        UI.SetConsoleFont(@magic, @font, @screenMap, @unicodeMap, @language)
      end

      nil
    end

    # Check current configuration
    # This function should be called to check consistency with
    # other modules (mentioned as Depends in the header)
    # @return	0	if no change
    # 		1	change due to dependency with other module
    #		2	inconsistency detected
    #

    def Check
      true
    end

    # constructor
    # does nothing in initial mode
    # restores console configuration from /etc/sysconfig
    # in normal mode

    def Console
      if Stage.initial
        @serial = Linuxrc.InstallInf("Console")
        @serial = "" if @serial == nil
      else
        Restore()
      end

      nil
    end

    publish :function => :SelectFont, :type => "string (string)"
    publish :function => :Save, :type => "void ()"
    publish :function => :Restore, :type => "string ()"
    publish :function => :Init, :type => "void ()"
    publish :function => :Check, :type => "boolean ()"
    publish :function => :Console, :type => "void ()"

  private

    # Console fonts map
    #
    # Associates languages with the following set of properties: font, unicode map,
    # screen map and magic initialization.
    #
    # @example Console fonts format
    #   {
    #     "bg" => {
    #       "font"=>"UniCyr_8x16.psf",
    #       "unicodeMap"=>"",
    #       "screenMap"=>"trivial",
    #       "magic"=>"(K"
    #     },
    #     "bg_BG" => {
    #       "font"=>"UniCyr_8x16.psf",
    #       "unicodeMap"=>"",
    #       "screenMap"=>"trivial",
    #       "magic"=>"(K"
    #     }
    #   }
    #
    # @return [Hash] Console fonts map. See the example for content details.
    def consolefonts
      return @consolefonts if @consolefonts

      @consolefonts = JSON.load(File.read(Directory.find_data_file("consolefonts.json")))
    end
  end

  Console = ConsoleClass.new
  Console.main
end

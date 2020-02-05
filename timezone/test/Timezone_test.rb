#!/usr/bin/env rspec

require_relative "test_helper"
require "y2country/language_dbus"

Yast.import "ProductFeatures"

describe "Yast::Timezone" do
  let(:readonly_timezone) { false }
  let(:default_timezone) { "" }
  let(:initial) { false }

  before do
    allow(Y2Country).to receive(:read_locale_conf).and_return(nil)
    Yast.import "Timezone"
    allow(Yast::ProductFeatures).to receive(:GetBooleanFeature)
      .with("globals", "readonly_timezone").and_return(readonly_timezone)
    allow(Yast::ProductFeatures).to receive(:GetStringFeature)
      .with("globals", "timezone").and_return(default_timezone)
    allow(Yast::Stage).to receive(:initial).and_return(initial)
    Yast::Timezone.main
  end

  subject { Yast::Timezone }

  describe "#ProposeLocaltime" do
    subject { Yast::Timezone.ProposeLocaltime }

    it "returns true if a Windows partition is found" do
      Yast::Timezone.windows_partition = true
      allow(Yast::SCR).to receive(:Read)
        .with(path(".probe.is_vmware")).and_return(false)

      expect(subject).to eq(true)

      Yast::Timezone.windows_partition = false
    end

    it "returns true if running in VMware VM" do
      expect(Yast::SCR).to receive(:Read)
        .with(path(".probe.is_vmware")).and_return(true)

      expect(subject).to eq(true)
    end

    it "returns true if running in on a 32bit Mac" do
      allow(Yast::SCR).to receive(:Read)
        .with(path(".probe.is_vmware")).and_return(false)
      expect(Yast::Arch).to receive(:ppc32).and_return(true)
      expect(Yast::Arch).to receive(:board_mac).and_return(true)

      expect(subject).to eq(true)
    end

    it "returns false otherwise" do
      allow(Yast::SCR).to receive(:Read)
        .with(path(".probe.is_vmware")).and_return(false)
      expect(Yast::Arch).to receive(:board_mac).and_return(false)

      expect(subject).to eq(false)
    end

  end

  describe "#timezone" do
    context "when timezone is read-only during installation" do
      let(:readonly_timezone) { true }
      let(:initial) { true }

      it "returns 'UTC'" do
        expect(subject.timezone).to eq("UTC")
      end

      context "and default timezone is set" do
        let(:default_timezone) { "Atlantic/Canary" }

        it "returns the default timezone" do
          expect(subject.timezone).to eq("Atlantic/Canary")
        end
      end
    end
  end

  describe "#Set" do
    before do
      allow(Yast::Misc).to receive(:SysconfigRead).with(Yast::Path.new(".sysconfig.clock.TIMEZONE"))
        .and_return("Europe/Berlin")
      allow(Yast::Misc).to receive(:SysconfigRead).and_call_original
      allow(Yast::FileUtils).to receive(:IsLink).with("/etc/localtime").and_return(false)
    end

    it "returns the region number" do
      expect(subject.Set("Atlantic/Canary", false)).to eq(3)
    end

    it "modifies the timezone" do
      subject.Set("Atlantic/Canary", false)
      expect(subject.timezone).to eq("Atlantic/Canary")
    end

    context "when timezone is read-only during installation" do
      let(:readonly_timezone) { true }
      let(:installation) { true }
      let(:initial) { true }

      before do
        allow(Yast::Mode).to receive(:installation).and_return(true)
      end

      it "returns the region number" do
        expect(subject.Set("Atlantic/Canary", false)).to eq(10) # UTC
      end

      it "does not modify the timezone" do
        subject.Set("Atlantic/Canary", false)
        expect(subject.timezone).to eq("UTC")
      end
    end

    context "when timezone is read-only in a running system" do
      let(:readonly_timezone) { true }

      it "returns the region number" do
        expect(subject.Set("Atlantic/Canary", false)).to eq(3) # Atlantic
      end

      it "modifies the timezone" do
        subject.Set("Atlantic/Canary", false)
        expect(subject.timezone).to eq("Atlantic/Canary")
      end
    end
  end

  describe "#system_has_windows?" do
    before do
      allow(Yast::Arch).to receive(:x86_64).and_return(supported_arch)
      allow(Yast::Arch).to receive(:i386).and_return(supported_arch)
    end

    context "when the architecture is not supported for Windows" do
      let(:supported_arch) { false }

      it "does not probe the system" do
        expect(subject).to_not receive(:disk_analyzer)

        subject.system_has_windows?
      end

      it "returns false" do
        expect(subject.system_has_windows?).to eq(false)
      end
    end

    context "when the architecture is supported for Windows" do
      let(:supported_arch) { true }

      context "but the Storage stack is not available" do
        before do
          allow(subject).to receive(:disk_analyzer).and_raise(NameError)
        end

        it "returns false" do
          expect(subject.system_has_windows?).to eq(false)
        end
      end

      context "and the Storage stack is available" do
        before do
          allow(subject).to receive(:disk_analyzer).and_return(disk_analyzer)
        end

        let(:disk_analyzer) { double("Y2Storage::DiskAnalyzer", windows_system?: windows) }

        let(:windows) { false }

        context "and there is a Windows system" do
          let(:windows) { true }

          it "returns true" do
            expect(subject.system_has_windows?).to eq(true)
          end
        end

        context "and there is not a Windows system" do
          let(:windows) { false }

          it "returns false" do
            expect(subject.system_has_windows?).to eq(false)
          end
        end
      end
    end
  end

  describe "#readonly" do
    context "when timezone is read-only" do
      let(:readonly_timezone) { true }

      it "returns true" do
        expect(subject.readonly).to eq(true)
      end
    end

    context "when timezone is not read-only" do
      let(:readonly_timezone) { false }

      it "returns false" do
        expect(subject.readonly).to eq(false)
      end
    end
  end

  describe "#product_default_timezone" do
    let(:default_timezone) { "Atlantic/Canary" }

    it "returns the globals/timezone feature" do
      expect(subject.product_default_timezone).to eq(default_timezone)
    end

    context "when globals/timezone is not set" do
      let(:default_timezone) { "" }

      it "returns 'UTC'" do
        expect(subject.product_default_timezone).to eq("UTC")
      end
    end
  end

  describe "#GetDateTime" do
    context "real_time is set to true" do
      context "locale_format is set to false" do
        it "returns stripped time output without locale format" do
          expect(Yast::SCR).to receive(:Execute).with(
            path(".target.bash_output"),
            "/bin/date \"+%Y-%m-%d - %H:%M:%S\""
          ).and_return("stdout" => "2020-02-05 - 08:13:57\n")

          expect(subject.GetDateTime(true, false)).to eq "2020-02-05 - 08:13:57"
        end
      end

      context "locale_format is set to true" do
        it "returns stripped time output with locale format" do
          expect(Yast::SCR).to receive(:Execute).with(
            path(".target.bash_output"),
            "/bin/date \"+%c\""
          ).and_return("stdout" => "St??5.????nor??2020,??08:18:27??CET\n")

          expect(subject.GetDateTime(true, true)).to eq "St??5.????nor??2020,??08:18:27??CET"
        end
      end
    end

    context "real_time is set to false" do
      before do
        subject.diff = 1
        subject.timezone = ""

        allow(Yast::SCR).to receive(:Execute).with(
          path(".target.bash_output"),
          "/bin/date +%z"
        ).and_return("stdout" => "+0100\n")
      end

      context "locale_format is set to false" do
        it "returns stripped time output without locale format including time zone diff" do
          expect(Yast::SCR).to receive(:Execute).with(
            path(".target.bash_output"),
            "/bin/date \"+%Y-%m-%d - %H:%M:%S\" \"--date=now 3600sec\""
          ).and_return("stdout" => "2020-02-05 - 09:13:57\n")

          expect(subject.GetDateTime(false, false)).to eq "2020-02-05 - 09:13:57"
        end
      end

      context "locale_format is set to true" do
        it "returns stripped time output with locale format" do
          expect(Yast::SCR).to receive(:Execute).with(
            path(".target.bash_output"),
            "/bin/date \"+%c\" \"--date=now 3600sec\""
          ).and_return("stdout" => "St??5.????nor??2020,??09:18:27??CET\n")

          expect(subject.GetDateTime(false, true)).to eq "St??5.????nor??2020,??09:18:27??CET"
        end
      end
    end
  end

  describe "#GetDateTime" do
    it "returns map with parsed time including timezone differences" do
      subject.timezone = ""
      subject.diff = 2

      expect(Yast::SCR).to receive(:Execute).with(
        path(".target.bash_output"),
        "/bin/date +%z"
      ).and_return("stdout" => "+0100\n")

      expect(Yast::SCR).to receive(:Execute).with(
          path(".target.bash_output"),
          "/bin/date \"+%Y-%m-%d - %H:%M:%S\" \"--date=now 7200sec\""
        ).and_return("stdout" => "2020-02-05 - 09:13:57\n")

      expect(subject.GetDateTimeMap).to eq(
        "year" => "2020",
        "month" => "02",
        "day" => "05",
        "hour" => "09",
        "minute" => "13",
        "second" => "57"
      )
    end
  end

  describe "#GetTimezoneForLanguage" do
    it "returns timezone for given language" do
      expect(subject.GetTimezoneForLanguage("en_US", "default")).to eq "US/Eastern"
      expect(subject.GetTimezoneForLanguage("cs_CZ", "default")).to eq "Europe/Prague"
    end

    it "returns default timezone if not found" do
      expect(subject.GetTimezoneForLanguage("Klingon", "default")).to eq "default"
    end
  end
end

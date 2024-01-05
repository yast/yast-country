#!/usr/bin/env rspec

# Copyright (c) [2020] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require_relative "test_helper"
require "y2country/clients/timezone_auto"
require_relative "../src/include/timezone/dialogs"

describe Yast::TimezoneAutoClient do
  subject(:client) { Yast::TimezoneAutoClient.new }

  describe "#change" do
    before do
      allow(Yast::Wizard).to receive(:CreateDialog)
      allow(Yast::Wizard).to receive(:CloseDialog)
      allow(Yast::Wizard).to receive(:HideAbortButton)
      allow(client).to receive(:TimezoneDialog).with(
        { "enable_back" => true, "enable_next" => true }
      )
        .and_return(true)
    end

    it "runs timezone dialog" do
      expect(client).to receive(:TimezoneDialog).with(
        { "enable_back" => true, "enable_next" => true }
      )
        .and_return(true)
      client.change
    end

    it "returns the value from the timezone dialog" do
      expect(client.change).to eq(true)
    end
  end

  describe "#summary" do
    before do
      allow(Yast::Timezone).to receive(:Summary)
        .and_return("Timezone Summary")
    end

    it "returns the AutoYaST summary" do
      expect(client.summary).to eq("Timezone Summary")
    end
  end

  describe "#import" do
    let(:profile) do
      {
        "hwclock"  => "UTC",
        "timezone" => "America/New_York"
      }
    end

    before do
      allow(Yast::Timezone).to receive(:Set)
    end

    it "imports the profile" do
      expect(Yast::Timezone).to receive(:Import).with(profile)
      client.import(profile)
    end
  end

  describe "#export" do
    it "exports the profile" do
      expect(Yast::Timezone).to receive(:Export)
      client.export
    end
  end

  describe "#read" do
    it "reads timezone information" do
      expect(Yast::Timezone).to receive(:Read)
      client.read
    end
  end

  describe "#write" do
    it "writes timezone information" do
      expect(Yast::Timezone).to receive(:Save)
      client.write
    end

    it "returns the value from the finish client" do
      expect(Yast::Timezone).to receive(:Save).and_return(true)
      expect(client.write).to eq(true)
    end
  end

  describe "#reset" do
    it "resets the timezone setting" do
      expect(Yast::Timezone).to receive(:PopVal)
      client.reset
      expect(Yast::Timezone.modified).to eq(false)
    end
  end

  describe "#packages" do
    it "returns an empty hash (no packages to install)" do
      expect(client.packages).to eq({})
    end
  end

  describe "#modified?" do
    it "timezone settings are modified ?" do
      expect(Yast::Timezone).to receive(:Modified)
      client.modified?
    end
  end

  describe "#modified" do
    it "set to modified" do
      client.modified
      expect(client.modified?).to eq(true)
    end
  end

  describe "#fix_obsolete_timezones" do
    context "with an obsolete timezone" do
      let(:tz1) { "Asia/Beijing" }
      let(:tz2) { "Asia/Shanghai" }

      before do
        allow(Yast::Timezone).to receive(:Import)
        allow(Yast::Timezone).to receive(:timezone).and_return(tz1, tz2)
        allow(Yast::Timezone).to receive(:Set)
      end

      it "fixes the timezone to a valid one" do
        expect(Yast::Timezone).to receive(:Set)
        client.import("timezone" => tz1)
        expect(Yast::Timezone.timezone).to eq tz2
      end
    end

    context "with a valid timezone" do
      let(:tz1) { "Asia/Hong_Kong" }
      let(:tz2) { tz1 }

      before do
        allow(Yast::Timezone).to receive(:Import)
        allow(Yast::Timezone).to receive(:timezone).and_return(tz1, tz2)
      end

      it "leaves the timezone as it is" do
        expect(Yast::Timezone).not_to receive(:Set)
        client.import("timezone" => tz1)
        expect(Yast::Timezone.timezone).to eq tz2
      end
    end
  end
end

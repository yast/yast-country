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

describe Yast::TimezoneAutoClient do
  subject(:client) { Yast::TimezoneAutoClient.new }

  describe "#change" do
    before do
      allow(Yast::Wizard).to receive(:CreateDialog)
      allow(Yast::Wizard).to receive(:CloseDialog)
      allow(Yast::Wizard).to receive(:HideAbortButton)
      allow(subject).to receive(:TimezoneDialog).with(
        {"enable_back"=>true, "enable_next"=>true})
        .and_return(true)
    end

    it "runs timezone dialog" do
      expect(subject).to receive(:TimezoneDialog).with(
        {"enable_back"=>true, "enable_next"=>true})
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
    let(:profile) {
      {
        "hwclock" => "UTC",
        "timezone" => "America/New_York"
      }
    }

    it "imports the profile" do
      expect(Yast::Timezone).to receive(:Import).with(profile)
      client.import(profile)
    end
  end


  describe "#export" do
    let(:profile) {
      {
        "hwclock" => "UTC",
        "timezone" => "America/New_York"        
      }            
    }

    before do
      allow(Yast::Timezone).to receive(:Export).and_return(profile)
    end

    context "AY configuration UI" do
      before do
        allow(Yast::Mode).to receive(:config).and_return(true)
      end
      it "exports complete timezone information for the AutoYaST profile" do
        expect(client.export).to eq(profile)
      end
    end

    context "AY installation;" do
      before do
        allow(Yast::Mode).to receive(:config).and_return(false)
      end

      context "timezone settings are default values" do
        before do
          allow(Yast::Timezone).to receive(:ProposeLocaltime).
            and_return(false)
          allow(Yast::Timezone).to receive(:GetTimezoneForLanguage).
            and_return("America/New_York")
        end
        
        it "exports an empty hash for the AutoYaST profile" do
          expect(client.export).to eq({})
        end
      end

      context "timezone settings are not default values" do
        before do
          allow(Yast::Timezone).to receive(:ProposeLocaltime).
            and_return(true)
          allow(Yast::Timezone).to receive(:GetTimezoneForLanguage).
            and_return("America/Denver")
        end
        
        it "exports timezone information for the AutoYaST profile" do
          expect(client.export).to eq(profile)
        end
      end
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
end

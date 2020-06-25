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
require "y2country/clients/language_auto"

describe Language::AutoClient do
  subject(:client) { Language::AutoClient.new }

  describe "#change" do
    before do
      allow(Yast::WFM).to receive(:CallFunction).with(
        "select_language", [{"enable_back"=>true, "enable_next"=>true}])
        .and_return(true)
    end

    it "runs select_language client" do
      expect(Yast::WFM).to receive(:CallFunction).with(
        "select_language", [{"enable_back"=>true, "enable_next"=>true}])
      client.change
    end

    it "returns the value from the select_language client" do
      expect(client.change).to eq(true)
    end
  end

  describe "#summary" do
    before do
      allow(Yast::Language).to receive(:Summary)
        .and_return("Services List")
    end

    it "returns the AutoYaST summary" do
      expect(client.summary).to eq("Services List")
    end
  end

  describe "#import" do
    let(:profile) {
       {
          "language"  => "en_US",
          "languages" => "fr_FR,en_US,"
       }      
    }

    it "imports the profile" do
      expect(Yast::Language).to receive(:Import).with(profile)
      client.import(profile)
    end
  end

  describe "#export" do
    let(:profile) {
      {
        "language"  => "en_US",
        "languages" => "fr_FR,en_US,"
      }            
    }

    before do
      allow(Yast::Language).to receive(:Export).and_return(profile)
    end

    context "AY configuration UI" do
      before do
        allow(Yast::Mode).to receive(:autoyast_clone_system).and_return(false)
      end
      it "exports complete language information for the AutoYaST profile" do
        expect(client.export).to eq(profile)
      end
    end

    context "AY clone;" do
      before do
        allow(Yast::Mode).to receive(:autoyast_clone_system).and_return(true)
      end

      context "language settings are default values" do
        before do
          allow(Yast::Language).to receive(:language).
            and_return(Yast::Language.default_language)
          allow(Yast::Language).to receive(:languages).and_return("")
        end
        
        it "exports an empty hash for the AutoYaST profile" do
          expect(client.export).to eq({})
        end
      end

      context "language settings are not default values" do
        before do
          allow(Yast::Language).to receive(:language).and_return("foo")
          allow(Yast::Language).to receive(:languages).and_return("fr_FR,en_US,")
        end
        
        it "exports language information for the AutoYaST profile" do
          expect(client.export).to eq(profile)
        end
      end
    end
  end

  describe "#read" do
    it "reads language information" do
      expect(Yast::Language).to receive(:Read)
      client.read
    end
  end

  describe "#write" do
    it "writes language information" do
      expect(Yast::Language).to receive(:Save)
      # setting console
      expect(Yast::Console).to receive(:SelectFont)
      expect(Yast::Console).to receive(:Save)
      client.write
    end
    
    it "returns the value from the finish client" do
      expect(Yast::Language).to receive(:Save).and_return(true)      
      expect(client.write).to eq(true)
    end
  end

  describe "#reset" do
    it "resets the language setting" do
      expect(Yast::Language).to receive(:Import)
      client.reset
      expect(Yast::Language.ExpertSettingsChanged).to eq(false)
    end
  end

  describe "#packages" do
    it "returns an empty hash (no packages to install)" do
      expect(client.packages).to eq({})
    end
  end

  describe "#modified?" do
    it "language information is modified ?" do
      expect(Yast::Language).to receive(:Modified)
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

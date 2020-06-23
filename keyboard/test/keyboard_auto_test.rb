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
require "y2keyboard/clients/keyboard_auto"

describe Keyboard::AutoClient do
  subject(:client) { Keyboard::AutoClient.new }

  describe "#change" do
    before do
      allow(Yast::WFM).to receive(:CallFunction).with(
        "keyboard")
        .and_return(true)
    end

    it "runs keyboard client" do
      expect(Yast::WFM).to receive(:CallFunction).with(
        "keyboard")
      client.change
    end

    it "returns the value from the keyboard client" do
      expect(client.change).to eq(true)
    end
  end

  describe "#summary" do
    before do
      allow(Yast::Keyboard).to receive(:Summary)
        .and_return("Keyboard")
    end

    it "returns the AutoYaST summary" do
      expect(client.summary).to eq("Keyboard")
    end
  end

  describe "#import" do
    let(:profile) {{ "keymap" => "english-us" }}

    it "imports the profile" do
      expect(Yast::Keyboard).to receive(:Import).with(profile)
      client.import(profile)
    end
  end

  describe "#export" do
    let(:profile) {{ "keymap" => "english-us" }}

    before do
      allow(Yast::Keyboard).to receive(:Export).and_return(profile)
    end

    context "AY configuration UI" do
      before do
        allow(Yast::Mode).to receive(:config).and_return(true)
      end
      it "exports complete keyboard information for the AutoYaST profile" do
        expect(client.export).to eq(profile)
      end
    end

    context "AY installation;" do
      before do
        allow(Yast::Mode).to receive(:config).and_return(false)
      end

      context "keyboard settings are default values, depending on language" do
        before do
          allow(Yast::Keyboard).to receive(:GetKeyboardForLanguage).
            and_return("english-us")
        end
        
        it "exports an empty hash for the AutoYaST profile" do
          expect(client.export).to eq({})
        end
      end

      context "keyboard settings are not default values" do
        before do
          allow(Yast::Keyboard).to receive(:GetKeyboardForLanguage).
            and_return("german")
        end
        
        it "exports keyboard information for the AutoYaST profile" do
          expect(client.export).to eq(profile)
        end
      end
    end
  end

  describe "#read" do
    it "reads keyboard information" do
      expect(Yast::Keyboard).to receive(:Read)
      client.read
    end
  end

  describe "#write" do
    it "writes keyboard information" do
      expect(Yast::Keyboard).to receive(:Save)
      client.write
    end
    
    it "returns the value from the finish client" do
      expect(Yast::Keyboard).to receive(:Save).and_return(nil)
      expect(client.write).to eq(nil)
    end
  end

  describe "#reset" do
    it "resets the keyboard setting" do
      expect(Yast::Keyboard).to receive(:Import)
      client.reset
    end
  end

  describe "#packages" do
    it "returns an empty hash (no packages to install)" do
      expect(client.packages).to eq({})
    end
  end

  describe "#modified?" do
    it "keyboard settings are modified ?" do
      expect(Yast::Keyboard).to receive(:Modified)
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

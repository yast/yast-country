#!/usr/bin/env rspec

require_relative "test_helper"

Yast.import "Timezone"

describe Yast::Timezone do

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
end

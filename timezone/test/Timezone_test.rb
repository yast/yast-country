#!/usr/bin/env rspec

require_relative "test_helper"

Yast.import "Timezone"

describe Yast::Timezone do
  subject { Yast::Timezone }

  describe "#ProposeLocaltime" do
    it "returns true if a Windows partition is found" do
      subject.windows_partition = true
      expect(Yast::SCR).to receive(:Read)
        .with(Yast::Path.new(".probe.is_vmware")).and_return(false)

      expect(subject.ProposeLocaltime).to eq(true)

      subject.windows_partition = false
    end

    it "returns true if running in VMware VM" do
      expect(Yast::SCR).to receive(:Read)
        .with(Yast::Path.new(".probe.is_vmware")).and_return(true)

      expect(subject.ProposeLocaltime).to eq(true)
    end

    it "returns true if running in on a 32bit Mac" do
      expect(Yast::SCR).to receive(:Read)
        .with(Yast::Path.new(".probe.is_vmware")).and_return(false)
      expect(Yast::Arch).to receive(:ppc32).and_return(true)
      expect(Yast::Arch).to receive(:board_mac).and_return(true)

      expect(subject.ProposeLocaltime).to eq(true)
    end

    it "returns false otherwise" do
      expect(Yast::SCR).to receive(:Read)
        .with(Yast::Path.new(".probe.is_vmware")).and_return(false)
      expect(Yast::Arch).to receive(:board_mac).and_return(false)

      expect(subject.ProposeLocaltime).to eq(false)
    end
    
  end
end

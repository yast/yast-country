#!/usr/bin/env rspec

require_relative "test_helper"

Yast.import "Timezone"
Yast.import "ProductFeatures"

describe Yast::Timezone do
  let(:readonly_timezone) { false }
  let(:default_timezone) { "" }
  let(:initial) { false }

  before do
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
    context "when timezone is read-only during installation" do
      let(:readonly_timezone) { true }
      let(:initial) { true }

      it "returns -1" do
        expect(subject.Set("Atlantic/Canary", true)).to eq(-1)
      end

      it "does not modify the timezone" do
        subject.Set("Atlantic/Canary", true)
        expect(subject.timezone).to eq("UTC")
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
end

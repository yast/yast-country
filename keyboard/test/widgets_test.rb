#!/usr/bin/env rspec

require_relative 'test_helper'
require "y2country/widgets"

describe Y2Country::Widgets::KeyboardSelection do
  subject { described_class.new("english-us") }
  it "has label" do
    expect(subject.label).to be_a(::String)
  end

  it "has help" do
    expect(subject.help).to be_a(::String)
  end

  it "enlists all available keyboard layoout" do
    expect(subject.items).to include(["english-us", "English (US)"])
  end

  it "changes keyboard layout when value changed" do
    expect(Yast::Keyboard).to receive(:Set)

    subject.handle
  end

  it "passes notify option to widget" do
    expect(subject.opt).to eq [:notify]
  end

  it "stores keyboard layout" do
    expect(Yast::Keyboard).to receive(:Set)

    subject.store
  end

  context "when keyboard layout already set" do
    before do
      allow(Yast::Keyboard).to receive(:user_decision).and_return(true)
    end

    it "initizalizes widget to previous selection" do
      allow(Yast::Keyboard).to receive(:current_kbd).and_return("english-uk")

      expect(subject).to receive(:value=).with("english-uk")

      subject.init
    end
  end

  context "when keyboard layout not yet set" do
    before do
      allow(Yast::Keyboard).to receive(:user_decision).and_return(false)
    end

    it "initizalizes widget to english us layout" do
      expect(subject).to receive(:value=).with("english-us")

      subject.init
    end

    it "initializes that default layout" do
      expect(subject).to receive(:value).and_return("english-us")

      expect(Yast::Keyboard).to receive(:Set).with("english-us")

      subject.init
    end
  end
end

#!/usr/bin/env rspec

require_relative "../test_helper"
require "cwm/rspec"
require "y2country/language_dbus"

describe "Y2Country::Widgets::KeyboardSelection" do
  subject { Y2Country::Widgets::KeyboardSelection.new("english-us") }

  include_examples "CWM::AbstractWidget"

  before do
    allow(Y2Country).to receive(:read_locale_conf).and_return(nil)
    require "y2country/widgets/keyboard_selection"
  end

  it "enlists all available keyboard layoout" do
    expect(subject.items).to include(["english-us", "English (US)"])
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

    it "initializes widget to previous selection" do
      allow(Yast::Keyboard).to receive(:current_kbd).and_return("english-uk")

      expect(subject).to receive(:value=).with("english-uk")

      subject.init
    end
  end

  context "when keyboard layout not yet set" do
    before do
      allow(Yast::Keyboard).to receive(:user_decision).and_return(false)
      allow(Yast::Language).to receive(:language).and_return("english-us")
    end

    it "initializes widget to english us layout" do
      expect(subject).to receive(:value=).with("english-us")

      subject.init
    end

    it "initializes that default layout" do
      expect(subject).to receive(:value).and_return("english-us")

      expect(Yast::Keyboard).to receive(:Set).with("english-us")

      subject.init
    end
  end

  describe "#handle" do
    before do
      allow(Yast::Keyboard).to receive(:current_kbd).and_return(initial_kbd)
      allow(subject).to receive(:value).and_return(selected_value)
    end

    context "when keyboard is not changed" do
      let(:initial_kbd) { "english-us" }
      let(:selected_value) { "english-us" }

      it "does not try to set the keyboard again" do
        expect(subject).to receive(:value).and_return("english-us")
        expect(Yast::Keyboard).to_not receive(:Set)

        subject.handle
      end
    end

    context "when keyboard has changed" do
      let(:initial_kbd) { "english-us" }
      let(:selected_value) { "spanish" }

      it "sets the new value" do
        expect(Yast::Keyboard).to receive(:Set).with("spanish")
        expect(Yast::Keyboard).to receive(:user_decision=).with(true)

        subject.handle
      end
    end
  end
end

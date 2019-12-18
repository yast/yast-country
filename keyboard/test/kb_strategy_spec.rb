require_relative "test_helper"
require "y2keyboard/strategies/kb_strategy"
require "yast"

Yast.import "UI"

describe Y2Keyboard::Strategies::KbStrategy do
  subject(:kb_strategy) { Y2Keyboard::Strategies::KbStrategy.new }
  let(:arguments_to_apply) {"-layout es -model microsoftpro -option terminate:ctrl_alt_bksp"}
  

  describe "#set_layout" do
    context "in text mode" do
      before do
        allow(Yast::UI).to receive(:TextMode).and_return(true)
      end

      it "calls -loadkeys- on the target" do
        expect(Yast::Execute).to receive(:on_target!).twice.with(
          "loadkeys", anything, "es")

        kb_strategy.set_layout("es")
      end

      it "does not call any X11 stuff" do
        expect(kb_strategy).not_to receive(:set_x11_layout)

        kb_strategy.set_layout("es")
      end
    end

    context "in X11 mode" do
      before do
        allow(Yast::UI).to receive(:TextMode).and_return(false)
      end

      it "does not call -loadkeys- on the target" do
        expect(Yast::Execute).not_to receive(:on_target!).with(
          "loadkeys", anything, "es")
        expect(kb_strategy).to receive(:set_x11_layout)        

        kb_strategy.set_layout("es")
      end

      it "calls setxkbmap and sets rules" do
        allow(Yast::Stage).to receive(:initial).and_return true
        expect(kb_strategy).to receive(:get_x11_data).with("es").and_return(
          {"XkbLayout"  => "es",
           "XkbModel"   => "microsoftpro",
           "XkbOptions" => "terminate:ctrl_alt_bksp",
           "Apply"      => arguments_to_apply})
        expect(Kernel).to receive(:system).with(
          "/usr/bin/setxkbmap #{arguments_to_apply}")
        expect(kb_strategy).to receive(:write_udev_rule)

        kb_strategy.set_layout("es")
      end
    end

    context "empty keyboard_code parameter" do
      it "returns only " do
        expect(kb_strategy).not_to receive(:set_x11_layout)
        expect(Yast::Execute).not_to receive(:on_target!).with(
          "loadkeys", anything, anything)
        kb_strategy.set_layout("")
      end
    end
  end
end

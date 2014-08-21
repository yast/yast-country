#!/usr/bin/env rspec

require_relative 'test_helper'
require_relative 'SCRStub'

module Yast
  import "Stage"
  import "Mode"
  import "Linuxrc"
  import "Path"
  import "Encoding"
  import "AsciiFile"

  RSpec.configure do |c|
    c.include SCRStub
  end

  describe "Keyboard" do
    before(:each) do
      allow(Stage).to receive(:stage).and_return stage
      allow(Mode).to receive(:mode).and_return mode
      allow(Linuxrc).to receive(:text).and_return false

      init_root_path(chroot)
    end

    after(:each) do
      cleanup_root_path(chroot)
    end

    describe "#Save" do
      before(:each) do
        stub_presence_of "/usr/sbin/xkbctrl"
        allow(XVersion).to receive(:binPath).and_return "/usr/bin"
        # Stub the configuration writing...
        stub_scr_write
        # ...but allow the dump_xkbctrl helper to use SCR.Write
        allow(SCR).to receive(:Write).with(SCRStub::STRING_PATH, anything, anything).and_call_original
      end

      context "during installation" do
        let(:mode) { "installation" }
        let(:stage) { "initial" }
        let(:chroot) { "installing" }

        it "writes the configuration" do
          expect_to_execute(/loadkeys es\.map\.gz/)
          # Called twice, for SetConsole and SetX11
          expect_to_execute(/xkbctrl es/).twice do |p, cmd|
            dump_xkbctrl(:spanish, cmd.split("> ")[1])
          end
          expect_to_execute(/setxkbmap .*layout es/)
          expect_to_execute(/localectl --no-convert set-x11-keymap es microsoftpro basic$/)
          # SetX11 sets autorepeat during installation
          expect_to_execute(/xset r on$/)
          expect(AsciiFile).to receive(:AppendLine).with(anything, ["Keytable:", "es.map.gz"])

          Keyboard.Set("spanish")
          Keyboard.Save

          expect(written_value_for(".sysconfig.keyboard.YAST_KEYBOARD")).to eq("spanish,pc104")
          expect(written_value_for(".sysconfig.keyboard")).to be_nil
          expect(written_value_for(".etc.vconsole_conf.KEYMAP")).to eq("es")
          expect(written_value_for(".etc.vconsole_conf")).to be_nil
        end

        it "doesn't regenerate initrd" do
          expect(Initrd).to_not receive(:Read)
          expect(Initrd).to_not receive(:Update)
          expect(Initrd).to_not receive(:Write)

          Keyboard.Save
        end
      end

      context "in an installed system" do
        let(:mode) { "normal" }
        let(:stage) { "normal" }
        let(:chroot) { "spanish" }

        it "writes the configuration" do
          expect_to_execute(/loadkeys ruwin_alt-UTF-8\.map\.gz/)
          # Called twice, for SetConsole and SetX11
          expect_to_execute(/xkbctrl ruwin_alt-UTF-8/).twice do |p, cmd|
            dump_xkbctrl(:russian, cmd.split("> ")[1])
          end
          expect_to_execute(/setxkbmap .*layout us,ru/)
          expect_to_execute(/localectl --no-convert set-x11-keymap us,ru microsoftpro ,winkeys grp:ctrl_shift_toggle,grp_led:scroll$/)

          Keyboard.Set("russian")
          Keyboard.Save

          expect(written_value_for(".sysconfig.keyboard.YAST_KEYBOARD")).to eq("russian,pc104")
          expect(written_value_for(".sysconfig.keyboard")).to be_nil
          expect(written_value_for(".etc.vconsole_conf.KEYMAP")).to eq("ruwin_alt-UTF-8")
          expect(written_value_for(".etc.vconsole_conf")).to be_nil
        end

        it "does regenerate initrd" do
          expect(Initrd).to receive(:Read)
          expect(Initrd).to receive(:Update)
          expect(Initrd).to receive(:Write)

          Keyboard.Save
        end
      end
    end

    describe "#Set" do
      let(:mode) { "normal" }
      let(:stage) { "normal" }
      let(:chroot) { "spanish" }

      it "correctly sets all layout variables" do
        expect_to_execute(/loadkeys ruwin_alt-UTF-8\.map\.gz/)

        Keyboard.Set("russian")
        expect(Keyboard.current_kbd).to eq("russian")
        expect(Keyboard.kb_model).to eq("pc104")
        expect(Keyboard.keymap).to eq("ruwin_alt-UTF-8.map.gz")
      end

      it "calls setxkbmap if graphical system is installed" do
        stub_presence_of "/usr/sbin/xkbctrl"
        allow(XVersion).to receive(:binPath).and_return "/usr/bin"

        expect_to_execute(/loadkeys trq\.map\.gz/)
        # Called twice, for SetConsole and SetX11
        expect_to_execute(/xkbctrl trq\.map\.gz/).twice do |p, cmd|
          dump_xkbctrl(:turkish, cmd.split("> ")[1])
        end
        expect_to_execute(/setxkbmap .*layout tr/)

        Keyboard.Set("turkish")
      end

      it "does not call setxkbmap if graphical system is not installed" do
        expect_to_execute(/loadkeys ruwin_alt-UTF-8\.map\.gz/)
        expect_to_execute(/xkbctrl ruwin_alt-UTF-8.map.gz/).never
        expect_to_execute(/setxkbmap/).never

        Keyboard.Set("russian")
      end
    end
  end
end

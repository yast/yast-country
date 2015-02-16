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
  import "XVersion"

  ::RSpec.configure do |c|
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
        allow(SCR).to receive(:Write)
          .with(path(".target.string"), anything, anything).and_call_original
        allow(SCR).to receive(:Read).with(path(".probe.keyboard.manual")).and_return([])
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

    describe "#SetX11" do
      before(:each) do
        stub_presence_of "/usr/sbin/xkbctrl"
        allow(XVersion).to receive(:binPath).and_return "/usr/bin"
      end

      context "during installation" do
        let(:mode) { "installation" }
        let(:stage) { "initial" }
        let(:chroot) { "installing" }

        it "creates temporary udev rule" do
          # Twice, one for SetKeyboard and again for SetX11
          expect_to_execute(/xkbctrl es/).twice do |p, cmd|
            dump_xkbctrl(:spanish, cmd.split("> ")[1])
          end
          expect_to_execute(/setxkbmap .*layout es/)

          rule = "# Generated by Yast to handle the layout of keyboards connected during installation\n"
          rule += 'ENV{ID_INPUT_KEYBOARD}=="1", ENV{XKBLAYOUT}="es", ENV{XKBMODEL}="microsoftpro", ENV{XKBVARIANT}="basic"'
          file = "/usr/lib/udev/rules.d/70-installation-keyboard.rules"
          expect(SCR).to receive(:Execute).with(path(".target.remove"), file)
          expect(SCR).to receive(:Write).with(path(".target.string"), file, "#{rule}\n")
          expect(SCR).to receive(:Write).with(path(".target.string"), file, nil)

          Keyboard.SetKeyboard("spanish")
          Keyboard.SetX11("spanish")
        end
      end

      context "in an installed system" do
        let(:mode) { "normal" }
        let(:stage) { "normal" }
        let(:chroot) { "spanish" }

        it "does not create udev rules" do
          # Twice, one for SetKeyboard and again for SetX11
          expect_to_execute(/xkbctrl trq/).twice do |p, cmd|
            dump_xkbctrl(:turkish, cmd.split("> ")[1])
          end
          expect_to_execute(/setxkbmap .*layout tr/)

          expect(SCR).to_not receive(:Execute)
            .with(path(".target.remove"), anything)
          expect(SCR).to_not receive(:Write).with(path(".target.string"),
                                                  "/etc/udev/rules.d/70-keyboard.rules",
                                                  anything)
          Keyboard.SetKeyboard("turkish")
          Keyboard.SetX11("turkish")
        end
      end
    end

    describe "Import" do
      let(:mode) { "autoinstallation" }
      let(:stage) { "initial" }
      let(:chroot) { "installing" }
      let(:discaps) { Keyboard.GetExpertValues["discaps"] }
      let(:default) { "english-us" }
      let(:default_expert_values) {
        {"rate" => "", "delay" => "", "numlock" => "", "discaps" => false}
      }

      before do
        # Let's ensure the initial state
        Keyboard.SetExpertValues(default_expert_values)
        allow(AsciiFile).to receive(:AppendLine).once.with(anything, ["Keytable:", "us.map.gz"])
        Keyboard.Set(default)
      end

      context "from a <keyboard> section" do
        let(:map) { {"keymap" => "spanish", "keyboard_values" => {"discaps" => true}} }

        it "sets the layout and the expert values" do
          expect(Keyboard).to receive(:Set).with("spanish")
          Keyboard.Import(map, :keyboard)
          expect(discaps).to eq(true)
        end

        it "ignores everything if the language section was expected" do
          expect(Keyboard).to receive(:Set).with(default)
          Keyboard.Import(map, :language)
          expect(discaps).to eq(false)
        end
      end

      context "from a <language> section" do
        let(:map) { {"language" => "es_ES"} }

        it "sets the layout and leaves expert values untouched" do
          expect(Keyboard).to receive(:Set).with("spanish")
          Keyboard.Import(map, :language)
          expect(discaps).to eq(false)
        end

        it "ignores everything if the keyboard section was expected" do
          expect(Keyboard).to receive(:Set).with(default)
          Keyboard.Import(map, :keyboard)
          expect(discaps).to eq(false)
        end
      end

      context "from a malformed input mixing <language> and <keyboard>" do
        let(:map) { {"language" => "es_ES", "keyboard_values" => {"discaps" => true}} }

        it "sets only the corresponding settings if a keyboard section was expected" do
          expect(Keyboard).to receive(:Set).with(default)
          Keyboard.Import(map, :keyboard)
          expect(discaps).to eq(true)
        end

        it "sets only the corresponding settings if a language section was expected" do
          expect(Keyboard).to receive(:Set).with("spanish")
          Keyboard.Import(map, :language)
          expect(discaps).to eq(false)
        end
      end
    end
  end
end

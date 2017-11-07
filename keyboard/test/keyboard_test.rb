#!/usr/bin/env rspec

require_relative 'test_helper'
require_relative 'SCRStub'

require "yaml"
require "y2country/language_dbus"

module Yast
  import "Stage"
  import "Mode"
  import "Linuxrc"
  import "Path"
  import "Encoding"
  import "AsciiFile"
  import "XVersion"
  import "Report"
  import "OSRelease"

  ::RSpec.configure do |c|
    c.include SCRStub
    c.include I18n
  end

  describe "Keyboard" do
    let(:udev_file) { "/usr/lib/udev/rules.d/70-installation-keyboard.rules" }
    let(:os_release_id) { "opensuse" }
    let(:mode) { "normal" }
    let(:stage) { "normal" }

    before(:each) do
      textdomain "country"
      allow(Y2Country).to receive(:read_locale_conf).and_return(nil)
      Yast.import "Keyboard"
      allow(OSRelease).to receive(:id).and_return(os_release_id)
      allow(Stage).to receive(:stage).and_return stage
      allow(Mode).to receive(:mode).and_return mode
      allow(Linuxrc).to receive(:text).and_return false
      allow(SCR).to receive(:Execute).with(path(".target.remove"), udev_file)
      allow(SCR).to receive(:Write).with(anything, udev_file, anything)
      allow(Installation).to receive(:destdir).and_return("/mnt")

      init_root_path(chroot) if defined?(chroot)
    end

    after(:each) do
      cleanup_root_path(chroot) if defined?(chroot)
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

        allow(SCR).to execute_bash(/loadkeys/)
        allow(SCR).to execute_bash(/xkbctrl/) do |p, cmd|
          dump_xkbctrl(new_lang, cmd.split("> ")[1])
        end
        allow(SCR).to execute_bash(/setxkbmap/)
        # SetX11 sets autorepeat during installation
        allow(SCR).to execute_bash(/xset r on$/)
      end

      context "during installation" do
        let(:mode) { "installation" }
        let(:stage) { "initial" }
        let(:chroot) { "installing" }
        let(:new_lang) { "spanish" }

        it "writes the configuration" do
          expect(SCR).to execute_bash_output(
            /systemd-firstboot --keymap 'es'$/
          )
          expect(AsciiFile).to receive(:AppendLine).with(anything, ["Keytable:", "es.map.gz"])

          Keyboard.Set("spanish")
          Keyboard.Save

          expect(written_value_for(".sysconfig.keyboard.YAST_KEYBOARD")).to eq("spanish,pc104")
          expect(written_value_for(".sysconfig.keyboard")).to be_nil
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
        let(:new_lang) { "russian" }

        it "writes the configuration" do
          expect(SCR).to execute_bash_output(
            /localectl set-keymap ruwin_alt-UTF-8$/
          )

          Keyboard.Set("russian")
          Keyboard.Save

          expect(written_value_for(".sysconfig.keyboard.YAST_KEYBOARD")).to eq("russian,pc104")
          expect(written_value_for(".sysconfig.keyboard")).to be_nil
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
        expect(SCR).to execute_bash(/loadkeys -C \/dev\/tty.* ruwin_alt-UTF-8\.map\.gz/)

        Keyboard.Set("russian")
        expect(Keyboard.current_kbd).to eq("russian")
        expect(Keyboard.kb_model).to eq("pc104")
        expect(Keyboard.keymap).to eq("ruwin_alt-UTF-8.map.gz")
      end

      it "calls setxkbmap if graphical system is installed" do
        stub_presence_of "/usr/sbin/xkbctrl"
        allow(XVersion).to receive(:binPath).and_return "/usr/bin"

        expect(SCR).to execute_bash(/loadkeys -C \/dev\/tty.* tr\.map\.gz/)
        # Called twice, for SetConsole and SetX11
        expect(SCR).to execute_bash(/xkbctrl tr\.map\.gz/).twice do |p, cmd|
          dump_xkbctrl(:turkish, cmd.split("> ")[1])
        end
        expect(SCR).to execute_bash(/setxkbmap .*layout tr/)

        Keyboard.Set("turkish")
      end

      it "does not call setxkbmap if graphical system is not installed" do
        expect(SCR).to execute_bash(/loadkeys -C \/dev\/tty.* ruwin_alt-UTF-8\.map\.gz/)
        expect(SCR).to execute_bash(/xkbctrl ruwin_alt-UTF-8.map.gz/).never
        expect(SCR).to execute_bash(/setxkbmap/).never

        Keyboard.Set("russian")
      end
    end

    describe "#SetX11" do
      subject { Keyboard.SetX11(new_lang) }

      before(:each) do
        stub_presence_of "/usr/sbin/xkbctrl"
        allow(XVersion).to receive(:binPath).and_return "/usr/bin"

        allow(SCR).to execute_bash(/xkbctrl/) do |p, cmd|
          dump_xkbctrl(new_lang, cmd.split("> ")[1])
        end

        # This needs to be called in advance
        Keyboard.SetKeyboard(new_lang)
      end

      context "during installation" do
        let(:mode) { "installation" }
        let(:stage) { "initial" }
        let(:chroot) { "installing" }
        let(:new_lang) { "spanish" }

        it "creates temporary udev rule" do
          allow(SCR).to execute_bash(/setxkbmap .*layout es/)
          allow(SCR).to execute_bash(/xset r on$/)

          rule = "# Generated by Yast to handle the layout of keyboards connected during installation\n"
          rule += 'ENV{ID_INPUT_KEYBOARD}=="1", ENV{XKBLAYOUT}="es", ENV{XKBMODEL}="microsoftpro"'
          expect(SCR).to receive(:Execute).with(path(".target.remove"), udev_file)
          expect(SCR).to receive(:Write).with(path(".target.string"), udev_file, "#{rule}\n")
          expect(SCR).to receive(:Write).with(path(".target.string"), udev_file, nil)

          subject
        end

        it "executes setxkbmap properly" do
          allow(SCR).to execute_bash(/xset r on$/)
          expect(SCR).to execute_bash(/setxkbmap .*layout es/).and_return(0)
          expect(Report).not_to receive(:Error)

          subject
        end

        it "alerts user if setxkbmap failed" do
          allow(SCR).to execute_bash(/xset r on$/)
          allow(SCR).to execute_bash(/setxkbmap/).and_return(253)
          expect(Report).to receive(:Error)

          subject
        end

        it "sets autorepeat" do
          allow(SCR).to execute_bash(/setxkbmap .*layout es/)
          expect(SCR).to execute_bash(/xset r on$/)

          subject
        end

      end

      context "in an installed system" do
        let(:mode) { "normal" }
        let(:stage) { "normal" }
        let(:chroot) { "spanish" }
        let(:new_lang) { "turkish" }

        it "does not create udev rules" do
          allow(SCR).to execute_bash(/setxkbmap .*layout es/)

          expect(SCR).to_not receive(:Execute)
            .with(path(".target.remove"), anything)
          expect(SCR).to_not receive(:Write).with(path(".target.string"),
                                                  /udev\/rules\.d/,
                                                  anything)
          subject
        end

        it "executes setxkbmap properly" do
          expect(SCR).to execute_bash(/setxkbmap .*layout tr/).and_return(0)
          expect(Report).not_to receive(:Error)

          subject
        end

        it "alerts user if setxkbmap failed" do
          allow(SCR).to execute_bash(/setxkbmap/).and_return(253)
          expect(Report).to receive(:Error)

          subject
        end

        it "does not set autorepeat" do
          allow(SCR).to execute_bash(/setxkbmap .*layout es/)
          expect(SCR).not_to execute_bash(/xset r on$/)

          subject
        end
      end

      describe "skipping of configuration" do
        let(:mode) { "normal" }
        let(:stage) { "normal" }
        let(:chroot) { "spanish" }
        let(:new_lang) { "turkish" }

        before do
          ENV["DISPLAY"] = display
        end

        context "when DISPLAY is empty" do
          let(:display) { "" }

          it "runs X11 configuration" do
            expect(SCR).to execute_bash(/setxkbmap/)
            subject
          end
        end

        context "when DISPLAY is nil" do
          let(:display) { nil }

          it "runs X11 configuration" do
            expect(SCR).to execute_bash(/setxkbmap/)
            subject
          end
        end

        context "when DISPLAY is < 10" do
          let(:display) { ":0" }

          it "runs X11 configuration" do
            expect(SCR).to execute_bash(/setxkbmap/)
            subject
          end
        end

        context "when DISPLAY is >= 10" do
          let(:display) { ":10" }

          it "skips X11 configuration" do
            expect(SCR).not_to execute_bash(/setxkbmap/)
            subject
          end
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

    describe "#Export" do
      let(:mode) { "normal" }
      let(:stage) { "normal" }
      let(:chroot) { "spanish" }

      it "exports configuration" do
        Keyboard.main
        expect(Keyboard.Export).to eq(
          {
            "keyboard_values" => {
              "delay" => "", "discaps" => false, "numlock" => "bios", "rate" => "" },
              "keymap" => "spanish"
          }
        )
      end
    end

    describe "#GetKeyboardForLanguage" do
      it "returns the keyboard for the given language" do
        expect(Keyboard.GetKeyboardForLanguage("cs_CZ", "en_US")).to eq("czech")
        expect(Keyboard.GetKeyboardForLanguage("en_US", "en_US")).to eq("english-us")
      end

      context "when the language does not exist" do
        it "returns the default keyboard" do
          expect(Keyboard.GetKeyboardForLanguage("other_OTHER", "english-us")).to eq("english-us")
        end
      end
    end

    describe "#MakeProposal" do
      let(:default_kbd) { "english-us" }
      let(:user_decision) { false }
      let(:current_kbd) { "czech" }

      before do
        Keyboard.user_decision = user_decision
        Keyboard.default_kbd = default_kbd
        Keyboard.current_kbd = current_kbd
      end

      it "returns the proposed keyboard name" do
        expect(Keyboard.MakeProposal(true, false)).to eq(_("English (US)"))
      end

      context "when reset is forced and a default keyboard is available" do
        it "sets the keyboard to the default value" do
          expect(Keyboard).to receive(:Set).with(default_kbd)
          Keyboard.MakeProposal(true, false)
        end

        it "sets user decision to false" do
          Keyboard.MakeProposal(true, false)
          expect(Keyboard.user_decision).to eq(false)
        end
      end

      context "when user made a decision and language changed" do
        let(:user_decision) { true }

        it "proposes the current keyboard" do
          expect(Keyboard).to receive(:Set).with(current_kbd)
          Keyboard.MakeProposal(false, true)
        end
      end

      context "when user did not make any decision" do
        it "sets the keyboard for the current language" do
          allow(Yast::Language).to receive(:language).and_return("english-us")
          expect(Keyboard).to receive(:Set).with("english-us")
          Keyboard.MakeProposal(false, false)
        end

        context "and a keyboard for the current language was not found" do
          before do
            allow(Keyboard).to receive(:GetKeyboardForLanguage)
              .and_return("")
          end

          it "sets the keyboard to the current value if language changed" do
            expect(Keyboard).to receive(:Set).with(current_kbd)
            Keyboard.MakeProposal(false, true)
          end

          it "does nothing if language did not change" do
            expect(Keyboard).to_not receive(:Set)
            Keyboard.MakeProposal(false, false)
          end
        end
      end
    end

    describe "#Probe" do
      let(:chroot) { "spanish" }
      let(:probed_data) { YAML.load_file(File.join(DATA_PATH, "probe-keyboard.yml")) }

      before do
        allow(SCR).to receive(:Read).with(path(".probe.keyboard"))
          .and_return(probed_data)
        allow(Keyboard).to receive(:SetKeyboard)
      end

      context "when layout can be determined" do
        it "sets keyboard data from hardware" do
          Keyboard.Probe
          expect(Keyboard.unique_key).to eq("nLyy.+49ps10DtUF")
          expect(Keyboard.kb_model).to eq("pc104")
        end

        it "sets the keyboard which matches the layout" do
          expect(Keyboard).to receive(:SetKeyboard).with("spanish")
          Keyboard.Probe
        end
      end

      context "when layout cannot be determined" do
        let(:probed_data) { nil }

        before { allow(Language).to receive(:language).and_return("es_ES") }

        it "uses the keyboard for the current language" do
          expect(Keyboard).to receive(:SetKeyboard).with("spanish")
          Keyboard.Probe
        end
      end

      context "during first stage" do
        let(:stage) { "initial" }

        before do
          allow(AsciiFile).to receive(:RewriteFile)
          allow(Linuxrc).to receive(:InstallInf).with("Keytable").and_return(keytable)
        end

        context "when Linuxrc Keytable setting exists" do
          let(:keytable) { "de-nodeadkeys" }

          it "uses the keyboard that matches the Keytable value" do
            expect(Keyboard).to receive(:Set).with("german").and_call_original
            Keyboard.Probe
          end

          it "sets the user decision to true" do
            Keyboard.Probe
            expect(Keyboard.user_decision).to eq(true)
          end
        end

        context "when Linuxrc Keytable is not present but a language is preselected" do
          let(:keytable) { nil }

          it "uses the default keyboard" do
            allow(Language).to receive(:preselected).and_return("es_ES")
            expect(Keyboard).to receive(:Set).with("spanish").and_call_original
            Keyboard.Probe
          end

          it "does not set the keyboard if preselected language is 'en_US'" do
            allow(Language).to receive(:preselected).and_return("en_US")
            expect(Keyboard).to_not receive(:Set)
            Keyboard.Probe
          end
        end
      end
    end

    describe "#Summary" do
      it "retuns an HTML containing the current layout" do
        Keyboard.SetKeyboard("spanish")
        # do not place translations to regexps or string interpolations
        # see bsc#1038077 for details, make sure the translation does
        # not contain special chars by accident
        label = Regexp.escape(_("Spanish"))
        expect(Keyboard.Summary)
          .to match /<li.*#{label}.*li>/
      end
    end

    describe "#Restore" do
      let(:chroot) { "spanish" }

      before do
        Keyboard.kb_model = "type4"
        Keyboard.current_kbd = "english-us"
      end

      it "restores settings from system configuration" do
        expect(Keyboard).to receive(:SetKeyboard)
          .with("spanish")
        expect(Keyboard.Restore).to eq(true)
        expect(Keyboard.kb_model).to eq("pc104")
        expect(Keyboard.current_kbd).to eq("spanish")
      end

      context "when value for keyboard is missing" do
        before do
          allow(Misc).to receive(:SysconfigRead).and_call_original
          allow(Misc).to receive(:SysconfigRead)
            .with(Path.new(".sysconfig.keyboard.YAST_KEYBOARD"), "")
            .and_return("")
        end

        it "restores to default values" do
          expect(Keyboard.Restore).to eq(false)
          expect(Keyboard.kb_model).to eq("pc104")
          expect(Keyboard.current_kbd).to eq("english-us")
        end
      end

      context "when running in config mode" do
        before { allow(Mode).to receive(:config).and_return(true) }

        it "does not set the keyboard" do
          expect(Keyboard).to_not receive(:SetKeyboard)
          expect(Keyboard.Restore).to eq(true)
        end
      end

      context "during 1st stage" do
        let(:stage) { "initial" }

        it "does not update model or current keyboard" do
          expect(Keyboard.Restore).to eq(true)
          expect(Keyboard.kb_model).to eq("type4")
          expect(Keyboard.current_kbd).to eq("english-us")
        end
      end
    end

    describe "#GetKeyboardName" do
      it "returns the keyboard name" do
        expect(Keyboard.GetKeyboardName("english-us")).to eq(_("English (US)"))
      end
    end

    describe "#get_reduced_keyboard_db" do
      let(:chroot) { "spanish" }
      let(:mode) { "normal" }
      let(:stage) { "normal" }
      let(:os_release_id) { "sles" }
      let(:kb_model) { "macintosh" }

      before { allow(Yast::OSRelease).to receive(:id).and_return(os_release_id) }

      around do |example|
        old_kb_model = Keyboard.kb_model
        Keyboard.kb_model = kb_model
        example.run
        Keyboard.kb_model = old_kb_model
      end

      it "returns generic version of the keyboard map" do
        reduced_db = Keyboard.get_reduced_keyboard_db
        expect(reduced_db["russian"].last["ncurses"])
          .to eq("mac-us.map.gz")
      end

      context "when using a product with an specific keyboard map" do
        let(:os_release_id) { "opensuse" }

        it "returns the specific version of the keyboard map" do
          reduced_db = Keyboard.get_reduced_keyboard_db
          expect(reduced_db["russian"].last["ncurses"])
            .to eq("us-mac.map.gz")
        end
      end
    end
  end
end

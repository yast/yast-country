require_relative "../../test/test_helper.rb"

SRC_PATH = File.expand_path("../../src", __FILE__)
DATA_PATH = File.join(File.expand_path(File.dirname(__FILE__)), "data")

# Used to Emulate the behaviour of
# /usr/sbin/xkbctrl xx.map.gz > /tmp/yy/xkbctrl.out
# without relying on xkbctrl being present in the machine running the test
def dump_xkbctrl(lang, file)
  case lang.to_s
  when 'turkish'
    content = <<END
$[
   "XkbLayout"    : "tr",
   "XkbModel"     : "microsoftpro",
   "XkbOptions"   : "caps:shift",
   "Apply"        : "-layout tr -option caps:shift -model microsoftpro"
]
END
  when 'spanish'
    content = <<END
$[
   "XkbLayout"    : "es",
   "XkbModel"     : "microsoftpro",
   "Apply"        : "-model microsoftpro -layout es"
]
END
  when 'russian'
    content = <<END
$[
   "XkbVariant"   : ",winkeys",
   "XkbLayout"    : "us,ru",
   "XkbModel"     : "microsoftpro",
   "XkbOptions"   : "grp:ctrl_shift_toggle,grp_led:scroll",
   "Apply"        : "-variant ,winkeys -model microsoftpro -option grp:ctrl_shift_toggle,grp_led:scroll -layout us,ru"
]
END
  end
  Yast::SCR.Execute(Yast::Path.new(".target.mkdir"), File.dirname(file))
  Yast::SCR.Write(Yast::Path.new(".target.string"), file, content)
end

# Closes the SCR instance open by set_root_path and cleans the chroot
def cleanup_root_path(directory)
  reset_root_path
  FileUtils.rmtree(File.join(DATA_PATH, directory, "tmp"))
  FileUtils.rmtree(File.join(DATA_PATH, directory, "data"))
end

# Sets and prepares the chroot for the whole testsuite and imports the
# keyboard module afterwards
def init_root_path(directory)
  # Copy data files into the chroot
  FileUtils.cp_r(File.join(SRC_PATH, "data"), File.join(DATA_PATH, directory))
  # chroot SCR
  root = File.join(DATA_PATH, directory)
  set_root_path(root)
  # In its current implementation import cannot be safelly loaded
  # without the previous mocking and chrooting
  import_keyboard
end

# Secure implementation of Yast.import "Keyboard"
#
# In most situations, Yast.import "Keyboard" will call Keyboard:Restore(),
# which calls xkbctrl and Encoding.Restore, so we need to catch both
def import_keyboard
  allow(Yast::SCR).to receive(:Execute).with(SCRStub::BASH_PATH, /xkbctrl es\.map\.gz/)
  # Just to prevent a not relevant call to 'locale -k"
  allow(Yast::Encoding).to receive(:Restore)
  Yast.import "Keyboard"
end

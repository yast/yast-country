# Helpers for stubbing several agent operations.
#
# Must be included in the configure section of RSpec.
#
# @example usage
#     RSpec.configure do |c|
#       c.include SCRStub
#     end
#
#     describe "Keyboard" do
#       it "uses loadkeys" do
#         expect_to_execute(/loadkeys/)
#         Keyboard.Set
#       end
#     end
#
module SCRStub
  YAST2_PATH = Yast::Path.new(".target.yast2")
  YCP_PATH = Yast::Path.new(".target.ycp")
  SIZE_PATH = Yast::Path.new(".target.size")
  BASH_PATH = Yast::Path.new(".target.bash")
  STRING_PATH = Yast::Path.new(".target.string")

  # Ensures that non-stubbed SCR calls still works as expected after including
  # the module in the testsuite
  # different methods of the module
  def self.included(testsuite)
    testsuite.before(:each) do
      allow(Yast::SCR).to receive(:Read).and_call_original
      allow(Yast::SCR).to receive(:Write).and_call_original
      allow(Yast::SCR).to receive(:Execute).and_call_original
    end
  end

  # Encapsulates subsequent SCR calls into a chroot.
  #
  # Raises an exception if something goes wrong.
  #
  # @param [#to_s] directory to use as '/' for SCR calls
  def set_root_path(directory)
    check_version = false
    @scr_handle = Yast::WFM.SCROpen("chroot=#{directory}:scr", check_version)
    raise "Error creating the chrooted scr instance" if @scr_handle < 0
    Yast::WFM.SCRSetDefault(@scr_handle)
    # Temporary workaround for bug bnc#891053 in yast2-core
    # Stubs all calls to target.yast2 until the bug is fixed
    allow(Yast::SCR).to receive(:Read).with(YAST2_PATH, anything) do |*args|
      Yast::SCR.Read(YCP_PATH, File.join("/data", args[1]))
    end
  end

  # Resets the SCR calls to default behaviour, closing the SCR instance open by
  # #set_root_path.
  #
  # Raises an exception if #set_root_path has not been called before (or if the
  # corresponding instance has already been closed)
  #
  # @see #set_root_path
  def reset_root_path
    default_handle = Yast::WFM.SCRGetDefault
    if default_handle != @scr_handle
      raise "Error closing the chrooted scr instance, it's not the current default one"
    end
    @scr_handle = nil
    Yast::WFM.SCRClose(default_handle)
  end

  # Stub calls to .target.size (used to check for the presence of a file)
  #
  # @param file to 'simulate'
  def stub_presence_of(file)
    # Returning any value > 0 will suffice
    allow(Yast::SCR).to receive(:Read).with(SIZE_PATH, file).and_return(256)
  end

  # Defines an expectation about executing commands using SCR.Execute and
  # .target.bash
  #
  # @return [MessageExpectation] an expectation (that can be further customized
  #       with usual RSpec methods)
  def expect_to_execute(command)
    expect(Yast::SCR).to(receive(:Execute).with(BASH_PATH, command))
  end

  # Stub all calls to SCR.Write storing the value for future comparison
  def stub_scr_write
    @written_values = {}
    allow(Yast::SCR).to receive(:Write) do |*args|
      @written_values[args[0].to_s] = args[1]
    end
  end

  # Value written by a stubbed call to SCR.Read
  #
  # @param key used in the call to SCR.Write
  def written_value_for(key)
    @written_values[key]
  end
end

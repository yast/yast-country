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

  # Stub calls to .target.size (used to check for the presence of a file)
  #
  # @param file to 'simulate'
  def stub_presence_of(file)
    # Returning any value > 0 will suffice
    allow(Yast::SCR).to receive(:Read).with(path(".target.size"), file)
      .and_return(256)
  end

  # Matcher for executing commands using SCR.Execute and .target.bash
  #
  # @return [RSpec::Mocks::Matchers::Receive]
  def execute_bash(command)
    receive(:Execute).with(path(".target.bash"), command)
  end

  # Matcher for executing commands using SCR.Execute and .target.bash_output
  #
  # @return [RSpec::Mocks::Matchers::Receive]
  def execute_bash_output(command)
    receive(:Execute).with(path(".target.bash_output"), command).and_return("exit" => 0)
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

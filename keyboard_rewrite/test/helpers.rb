module Helpers
  def given_layouts(layouts_to_return)
    allow(Cheetah).to receive(:run).with(
      "localectl", "list-keymaps", stdout: :capture
    ).and_return(layouts_to_return.join("\n"))
  end

  def mock_ui_events(*events)
    allow(Yast::UI).to receive(:UserInput).and_return(*events)
  end
end


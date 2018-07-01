# Spec helper for keyboard module tests
module KeyboardSpecHelper
  def mock_ui_events(*events)
    allow(Yast::UI).to receive(:UserInput).and_return(*events)
  end

  def given_layouts(layouts_to_return)
    allow(Cheetah).to receive(:run).with(
      "localectl", "list-keymaps", stdout: :capture
    ).and_return(layouts_to_return.join("\n"))
  end

  def given_a_current_layout(code)
    allow(Cheetah).to receive(:run)
      .with("localectl", "status", stdout: :capture)
      .and_return(
        "   System Locale: LANG=en_US.UTF-8\n" \
        "       VC Keymap: #{code}\n" \
        "       X11 Layout: #{code}\n" \
        "       X11 Model: microsoftpro\n" \
        "       X11 Options: terminate:ctrl_alt_bksp\n"
      )
  end

  def layout_definitions
    {"us"=>{"description"=>"English (US)"}, "uk"=>{"description"=>"English (UK)"}}
  end

  def selecting_layout_from_list(layout)
    allow(Yast::UI).to receive(:QueryWidget)
      .with(:layout_list, :CurrentItem)
      .and_return(layout.code)
  end

  def loadkeys_error
    Cheetah::ExecutionFailed.new(
      "loadkeys es",
      "Execution of \"loadkeys es\" failed with status 1: " \
      "Couldn't get a file descriptor referring to the console.",
      "",
      "Couldn't get a file descriptor referring to the console"
    )
  end

  def expect_display_layouts(layouts)
    allow(Yast::Term).to receive(:new).and_call_original
    layouts.each do |layout|
      expect(Yast::Term).to receive(:new).with(
        :item,
        Id(layout.code),
        layout.description,
        boolean
      )
    end
  end

  def expect_create_list_with_current_layout(layout)
    allow(Yast::Term).to receive(:new).and_call_original
    expect(Yast::Term).to receive(:new).with(
      :item,
      Id(layout.code),
      layout.description,
      true
    )
  end
end

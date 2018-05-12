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
        "       X11 Options: terminate:ctrl_alt_bksp\n")
  end

  def selecting_layout_from_list(layout)
    allow(Yast::UI).to receive(:QueryWidget)
        .with(:layout_list, :CurrentItem)
        .and_return(layout.description)
  end
end


module Y2Keyboard
  # This class represents a keyboard layout.
  class KeyboardLayout
    # @return [String] code of the keyboard layout, for example 'us'.
    attr_reader :code
    # @return [String] description of the keyboard layout, for example 'English (US)'.
    attr_reader :description

    def initialize(code, description)
      @code = code
      @description = description
    end
  end
end

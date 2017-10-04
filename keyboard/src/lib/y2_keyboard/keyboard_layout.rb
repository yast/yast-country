module Y2Keyboard
  class KeyboardLayout
    attr_reader :code

    def initialize(code)
      @code = code
    end
  end
end
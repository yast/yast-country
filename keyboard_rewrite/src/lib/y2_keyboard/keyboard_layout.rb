module Y2Keyboard
  class KeyboardLayout
    attr_reader :code
    attr_reader :description

    def initialize(code, description)
      @code = code
      @description = description
    end
  end
end

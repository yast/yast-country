module Y2Keyboard
  module Data
    LAYOUT_CODE_DESCRIPTIONS = {
      "gb" => "English (UK)",
      "es" => "Spanish",
      "fr" => "French",
      "us" => "English (US)"
    }.freeze

    def self.code_description_map
      LAYOUT_CODE_DESCRIPTIONS
    end
  end
end

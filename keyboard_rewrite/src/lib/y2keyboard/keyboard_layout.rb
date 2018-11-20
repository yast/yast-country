# Copyright (c) [2018] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

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

    # Define the strategy and layout definitions to use.
    # @param strategy [Object] the strategy to apply the changes in the system.
    # @param strategy [Array<Object>] codes availables to use in the application with the appropriate description
    def self.use(strategy, layout_definitions)
      @@strategy = strategy
      @@layout_definitions = layout_definitions
    end

    # @return [Array<KeyboardLayout>] an array with all available keyboard layouts.
    def self.all
      codes = @@strategy.codes
      layouts = @@layout_definitions.select { |x| codes.include?(x["code"]) }
      layouts.map { |x| KeyboardLayout.new(x["code"], x["description"]) }
    end

    def self.current_layout
      @@strategy.current_layout
    end

    # Apply a new keyboard layout in the system.
    def apply_layout
      @@strategy.apply_layout(self)
    end
  end
end

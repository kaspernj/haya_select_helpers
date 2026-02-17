require "haya_select"
require "haya_select_helpers/version"
require "haya_select_helpers/engine"

module HayaSelectHelpers
  def haya_select(id, debug: false)
    HayaSelect.new(id: id, scope: self, debug:)
  end
end

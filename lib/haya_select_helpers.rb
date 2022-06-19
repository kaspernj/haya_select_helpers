require "haya_select"
require "haya_select_helpers/version"
require "haya_select_helpers/engine"

module HayaSelectHelpers
  def haya_select(id)
    HayaSelect.new(id: id, scope: self)
  end
end

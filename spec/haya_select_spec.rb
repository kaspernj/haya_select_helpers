require "rails_helper"

class HayaSelectSpecScope
  attr_reader :page
end

describe HayaSelect do
  describe "#log_wait_for_selected_initial_state" do
    it "does not raise when hidden input is missing" do
      page = instance_double(Capybara::Session)
      scope = instance_double(HayaSelectSpecScope, page: page)
      value_input_selector = "[data-component='haya-select'][data-id='example'] [data-class='current-selected'] input[type='hidden']"

      expect(page).to receive(:has_selector?).with(value_input_selector, visible: false, wait: 0).and_return(false)
      expect(page).to receive(:first).with(value_input_selector, minimum: 0, visible: false, wait: 0).and_return(nil)
      expect(page).to receive(:first).with(
        "[data-component='haya-select'][data-id='example'] [data-class='current-selected'] [data-class='current-option']",
        minimum: 0,
        wait: 0
      ).and_return(nil)

      expect do
        HayaSelect.new(id: "example", scope: scope).__send__(:log_wait_for_selected_initial_state, value_input_selector)
      end.not_to raise_error
    end
  end

  describe "#value_no_wait" do
    it "returns nil when the hidden input is missing" do
      page = instance_double(Capybara::Session)
      scope = instance_double(HayaSelectSpecScope, page: page)

      expect(page).to receive(:first).with(
        "[data-component='haya-select'][data-id='example'] [data-class='current-selected'] input[type='hidden']",
        minimum: 0,
        visible: false,
        wait: 0
      ).and_return(nil)

      value = HayaSelect.new(id: "example", scope: scope).__send__(:value_no_wait)
      expect(value).to be_nil
    end
  end

  describe "#click_option_element" do
    it "ignores ElementNotInteractableError from location_once_scrolled_into_view" do
      scope = instance_double(Capybara::Session)
      native = instance_double(Selenium::WebDriver::Element)
      element = instance_double(Capybara::Node::Element, native: native)

      expect(native).to receive(:location_once_scrolled_into_view)
        .and_raise(Selenium::WebDriver::Error::ElementNotInteractableError)
      expect(element).to receive(:click)

      expect do
        HayaSelect.new(id: "example", scope: scope).__send__(:click_option_element, element)
      end.not_to raise_error
    end
  end
end

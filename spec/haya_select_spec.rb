require "rails_helper"

RSpec.describe HayaSelect do
  describe "#value_no_wait" do
    it "returns nil when the hidden input is missing" do
      page = instance_double(Capybara::Session)
      scope = instance_double("Scope", page: page)

      expect(page).to receive(:first).with(
        "[data-component='haya-select'][data-id='example'] [data-class='current-selected'] input[type='hidden']",
        minimum: 0,
        visible: false,
        wait: 0
      ).and_return(nil)

      value = described_class.new(id: "example", scope: scope).send(:value_no_wait)
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
        described_class.new(id: "example", scope: scope).send(:click_option_element, element)
      end.not_to raise_error
    end
  end
end

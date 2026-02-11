require "rails_helper"

RSpec.describe HayaSelect do
  describe "#click_option_element" do
    it "ignores ElementNotInteractableError from location_once_scrolled_into_view" do
      scope = instance_double(Capybara::Session)
      native = instance_double(Selenium::WebDriver::Element)
      element = instance_double(Capybara::Node::Element, native: native)

      allow(native).to receive(:location_once_scrolled_into_view)
        .and_raise(Selenium::WebDriver::Error::ElementNotInteractableError)
      expect(element).to receive(:click)

      expect do
        described_class.new(id: "example", scope: scope).send(:click_option_element, element)
      end.not_to raise_error
    end
  end
end

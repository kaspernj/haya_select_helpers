require "rails_helper"

class HayaSelectSpecScope
  attr_reader :page

  def wait_for_selector(*) = nil
end

describe HayaSelect do
  describe "#label_matches?" do
    it "matches by option data-text when rendered text differs" do
      page = instance_double(Capybara::Session)
      scope = instance_double(HayaSelectSpecScope, page: page)
      select = HayaSelect.new(id: "example", scope: scope)

      expect(page).to receive(:has_selector?).with(
        "[data-component='haya-select'][data-id='example'] [data-class='current-selected'] [data-testid='option-presentation'][data-text='Denmark +45']",
        wait: 0
      ).and_return(true)

      matches = select.__send__(:label_matches?, "Denmark +45")
      expect(matches).to be true
    end
  end

  describe "#selected_value_or_label_matches?" do
    it "does not accept selected option state while hidden input is stale" do
      page = instance_double(Capybara::Session)
      scope = instance_double(HayaSelectSpecScope, page: page)
      select = HayaSelect.new(id: "example", scope: scope)
      value_input_selector = "[data-component='haya-select'][data-id='example'] [data-class='current-selected'] input[type='hidden']"
      current_value_selector = "[data-component='haya-select'][data-id='example'] [data-class='current-selected'] input[type='hidden'][value='norway']"

      expect(page).to receive(:has_selector?).with(value_input_selector, visible: false, wait: 0).and_return(true)
      expect(page).to receive(:has_selector?).with(current_value_selector, visible: false, wait: 0).and_return(false)
      matches = select.__send__(
        :selected_value_or_label_matches?,
        label: nil,
        value: "norway",
        allow_blank: false,
        value_input_selector:
      )

      expect(matches).to be false
    end

    it "accepts selected option state while hidden input is not mounted yet" do
      page = instance_double(Capybara::Session)
      scope = instance_double(HayaSelectSpecScope, page: page)
      select = HayaSelect.new(id: "example", scope: scope)
      value_input_selector = "[data-component='haya-select'][data-id='example'] [data-class='current-selected'] input[type='hidden']"
      current_value_selector = "[data-component='haya-select'][data-id='example'] [data-class='current-selected'] input[type='hidden'][value='norway']"
      selected_option_selector = "[data-class='options-container'][data-id='example'] [data-class='select-option'][data-value='norway'][data-selected='true']"

      expect(page).to receive(:has_selector?).with(value_input_selector, visible: false, wait: 0).and_return(false)
      expect(page).to receive(:has_selector?).with(current_value_selector, visible: false, wait: 0).and_return(false)
      expect(page).to receive(:has_selector?).with(selected_option_selector, visible: :all, wait: 0).and_return(true)
      matches = select.__send__(
        :selected_value_or_label_matches?,
        label: nil,
        value: "norway",
        allow_blank: false,
        value_input_selector:
      )

      expect(matches).to be true
    end
  end

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

  describe "#wait_for_selected_value_or_label" do
    it "uses wait_for_selector for hidden input value when hidden input is mounted" do
      page = instance_double(Capybara::Session)
      value_input_selector = "[data-component='haya-select'][data-id='example'] [data-class='current-selected'] input[type='hidden']"
      current_value_selector = "[data-component='haya-select'][data-id='example'] [data-class='current-selected'] input[type='hidden'][value='norway']"
      scope = instance_double(HayaSelectSpecScope, page: page)
      select = HayaSelect.new(id: "example", scope: scope)

      expect(page).to receive(:has_selector?).with(value_input_selector, visible: false, wait: 0).and_return(true).twice
      expect(page).to receive(:first).with(value_input_selector, minimum: 0, visible: false, wait: 0).and_return(nil)
      expect(page).to receive(:first).with(
        "[data-component='haya-select'][data-id='example'] [data-class='current-selected'] [data-class='current-option']",
        minimum: 0,
        wait: 0
      ).and_return(nil)
      expect(scope).to receive(:wait_for_selector).with(current_value_selector, visible: false)

      select.__send__(:wait_for_selected_value_or_label, nil, "norway", allow_blank: false)
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

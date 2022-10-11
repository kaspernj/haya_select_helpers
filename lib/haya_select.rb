class HayaSelect
  attr_reader :base_selector, :not_opened_current_selected_selector, :opened_current_selected_selector, :options_selector, :scope

  delegate :all, :expect, :eq, :pretty_html, :wait_for_and_find, :wait_for_expect, :wait_for_no_selector, :wait_for_selector, to: :scope

  def initialize(id:, scope:)
    @base_selector = ".haya-select[data-id='#{id}']"
    @not_opened_current_selected_selector = "#{base_selector} .haya-select-current-selected[data-opened='false']"
    @opened_current_selected_selector = "#{base_selector} .haya-select-current-selected[data-opened='true']"
    @options_selector = ".haya-select-options-container[data-id='#{id}']"
    @scope = scope
  end

  def label
    wait_for_and_find("#{base_selector} .haya-select-current-selected .current-option").text
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end

  def open
    wait_for_and_find("#{base_selector} .haya-select-current-selected[data-opened='false']").click
    wait_for_selector opened_current_selected_selector
    wait_for_selector options_selector
    self
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end

  def options
    wait_for_selector "#{options_selector} .haya-select-option"
    option_elements = all("#{options_selector} .haya-select-option")
    option_elements.map do |option_element|
      {
        label: option_element.text,
        value: option_element["data-value"]
      }
    end
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end

  def wait_for_options(expected_options)
    wait_for_expect do
      expect(options).to eq expected_options
    end
  end

  def search(value)
    wait_for_and_find("#{base_selector} .haya-select-search-text-input").set(value)
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end

  def select(label)
    open
    select_option(label: label)
    wait_for_selector not_opened_current_selected_selector
    wait_for_no_selector options_selector
    self
  end

  def select_option(label:)
    wait_for_and_find("#{options_selector} .haya-select-option", exact_text: label).click
    self
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end

  def value
    wait_for_and_find("#{base_selector} .haya-select-current-selected input[type='hidden']", visible: false)[:value]
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end

  def wait_for_label(expected_label)
    wait_for_selector "#{base_selector} .haya-select-current-selected .current-option", exact_text: expected_label
    self
  end

  def toggles
    all(".haya-select-option-presentation").map do |element|
      {
        toggle_icon: element["data-toggle-icon"],
        toggle_value: element["data-toggle-value"],
        value: element["data-value"]
      }
    end
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end

  def wait_for_toggles(expected_toggles)
    wait_for_expect do
      expect(toggles).to eq expected_toggles
    end
  end

  def wait_for_value(expected_value)
    wait_for_selector "#{base_selector} .haya-select-current-selected input[type='hidden'][value='#{expected_value}']", visible: false
    self
  end
end

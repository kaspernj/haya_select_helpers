# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength, Style/Documentation
class HayaSelect
  attr_reader :base_selector,
    :not_opened_current_selected_selector,
    :opened_current_selected_selector,
    :options_selector,
    :scope

  delegate :all,
    :expect,
    :eq,
    :pretty_html,
    :wait_for_and_find,
    :wait_for_browser,
    :wait_for_expect,
    :wait_for_no_selector,
    :wait_for_selector,
    to: :scope

  def initialize(id:, scope:)
    @base_selector = "[data-component='haya-select'][data-id='#{id}']"
    @not_opened_current_selected_selector = "#{base_selector}[data-opened='false'] [data-class='current-selected']"
    @opened_current_selected_selector = "#{base_selector}[data-opened='true'] [data-class='current-selected']"
    @options_selector = "[data-class='options-container'][data-id='#{id}']"
    @scope = scope
  end

  def label
    wait_for_and_find("#{base_selector} [data-class='current-selected'] [data-class='current-option']").text
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end

  def open
    wait_for_and_find("#{base_selector}[data-opened='false'] [data-class='current-selected']").click
    wait_for_selector opened_current_selected_selector
    wait_for_selector options_selector
    self
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end

  def close
    wait_for_selector opened_current_selected_selector
    wait_for_and_find("[data-class='search-text-input']").click
    wait_for_no_selector opened_current_selected_selector
  end

  def options
    wait_for_selector "#{options_selector} [data-class='select-option']"
    option_elements = all("#{options_selector} [data-class='select-option']")
    option_elements.map do |option_element|
      {
        label: option_element.text,
        value: option_element['data-value']
      }
    end
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end

  def wait_for_options(expected_options)
    wait_for_expect do
      expect(options).to eq expected_options
    end
    self
  end

  def search(value)
    wait_for_and_find("#{base_selector} [data-class='search-text-input']").set(value)
    self
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end

  def select(label = nil, value: nil)
    open
    select_option(label:, value:)
    wait_for_selected_value_or_label(label, value)
    close_if_open
    self
  end

  def select_option(label: nil, value: nil)
    raise "No 'label' or 'value' given" if label.nil? && value.nil?

    selector = select_option_selector(label: label, value: value)
    wait_for_option(selector, label)
    option = wait_for_and_find(selector)

    raise "The '#{label}'-option is disabled" if option['data-disabled'] == 'true'

    option.click
    self
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end

  def value
    wait_for_and_find("#{base_selector} [data-class='current-selected'] input[type='hidden']", visible: false)[:value]
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end

  def wait_for_label(expected_label)
    wait_for_selector(
      "#{base_selector} [data-class='current-selected'] [data-class='current-option']",
      exact_text: expected_label
    )
    self
  end

  def toggles
    all("#{base_selector} [data-testid='option-presentation']").map do |element|
      {
        toggle_icon: element['data-toggle-icon'],
        toggle_value: element['data-toggle-value'],
        value: element['data-value']
      }
    end
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end

  def selected_option_values
    all("[data-class='select-option'][data-selected='true']").map do |select_option_element|
      select_option_element['data-value']
    end
  end

  def wait_for_selected_option_values(values)
    wait_for_expect do
      expect(selected_option_values).to eq values
    end
  end

  def wait_for_toggles(expected_toggles)
    wait_for_expect do
      expect(toggles).to eq expected_toggles
    end
    self
  end

  def wait_for_value(expected_value)
    wait_for_selector(
      "#{base_selector} [data-class='current-selected'] input[type='hidden'][value='#{expected_value}']",
      visible: false
    )
    self
  end

private

  def select_option_selector(label:, value:)
    selector = "#{options_selector} [data-testid='option-presentation']"
    selector << "[data-text='#{label}']" unless label.nil?
    selector << "[data-value='#{value}']" unless value.nil?
    selector
  end

  def wait_for_option(selector, label)
    search_for_option(label)
    wait_for_browser do
      scope.page.has_selector?(selector)
    end
  rescue WaitUtil::TimeoutError
    raise unless label

    search_for_option(label)
    wait_for_browser do
      scope.page.has_selector?(selector)
    end
  end

  def wait_for_selected_value_or_label(label, value)
    if value
      wait_for_value(value)
    elsif label
      wait_for_label(label)
    end
  end

  def search_for_option(label)
    return unless label
    return unless scope.page.has_selector?(search_input_selector)

    search(label)
  end

  def close_if_open
    return if scope.page.has_no_selector?(options_selector)

    if scope.page.has_selector?(select_container_selector)
      wait_for_and_find(select_container_selector).click
    else
      wait_for_and_find("body").click
    end

    wait_for_no_selector options_selector
    wait_for_selector not_opened_current_selected_selector
  end

  def search_input_selector
    "#{base_selector} [data-class='search-text-input']"
  end

  def select_container_selector
    "#{base_selector} [data-class='select-container']"
  end

  # rubocop:enable Metrics/ClassLength, Style/Documentation
end

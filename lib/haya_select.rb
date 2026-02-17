# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength, Style/Documentation
class HayaSelect
  attr_reader :base_selector,
    :debug,
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

  def initialize(id:, scope:, debug: false)
    @base_selector = "[data-component='haya-select'][data-id='#{id}']"
    @debug = debug
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

  def open(allow_if_open: false)
    if scope.page.has_selector?(options_selector, visible: :all, wait: 0)
      return self if allow_if_open

      raise "Expected haya-select '#{base_selector}' to be closed, but it was already open"
    end

    attempts = 0

    begin
      wait_for_selector("#{base_selector}[data-opened='false']", wait: 3)
      click_open_target_element
      wait_for_open
      self
    rescue WaitUtil::TimeoutError, Selenium::WebDriver::Error::StaleElementReferenceError
      attempts += 1
      retry if attempts < 3
      raise "Failed to open haya-select options for '#{base_selector}' (options container not found)"
    end
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
    search_input = wait_for_and_find("#{base_selector} [data-class='search-text-input']")
    search_input.set("")
    search_input.send_keys(value)
    self
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end

  def select(label = nil, value: nil, allow_if_selected: false)
    attempts = 0

    begin
      debug_log do
        "select start selector=#{base_selector} " \
          "label=#{label.inspect} value=#{value.inspect} " \
          "allow_if_selected=#{allow_if_selected} attempts=#{attempts}"
      end
      guard_already_selected(label, value, allow_if_selected) if attempts.zero?

      selected_value, allow_blank = select_value_and_close(label:, value:)
      wait_for_selected_after_select(label, value, selected_value, allow_blank)
      self
    rescue WaitUtil::TimeoutError, Selenium::WebDriver::Error::StaleElementReferenceError
      debug_log { "select retry selector=#{base_selector} attempts=#{attempts}" }
      attempts += 1
      retry if attempts < 3
      raise
    end
  end

  def guard_already_selected(label, value, allow_if_selected)
    return if allow_if_selected

    raise_if_value_already_selected(label, value)
    raise_if_label_already_selected(label, value)
  end

  def selected_label_for_value(value)
    return nil if value.nil? || value == ""

    was_open = scope.page.has_selector?(options_selector, visible: :all, wait: 0)
    self.open(allow_if_open: true)

    begin
      option = scope.page.first(
        "#{options_selector} [data-class='select-option'][data-value='#{value}']",
        minimum: 0,
        wait: 0
      )
      option&.[]("data-text") || option&.text
    ensure
      close_if_open unless was_open
    end
  end

  def value_no_wait
    hidden_input = scope.page.first(
      "#{base_selector} [data-class='current-selected'] input[type='hidden']",
      minimum: 0,
      visible: false,
      wait: 0
    )

    hidden_input ? hidden_input[:value] : nil
  end

  def label_no_wait
    current_option = scope.page.first(
      "#{base_selector} [data-class='current-selected'] [data-class='current-option']",
      minimum: 0,
      wait: 0
    )

    return nil unless current_option

    option_text = current_option.first("[data-testid='option-presentation-text']", minimum: 0)
    option_text ? option_text.text : current_option.text
  end

  def deselect(label: nil, value: nil)
    raise "No 'label' or 'value' given" if label.nil? && value.nil?

    attempts = 0

    begin
      option, option_value = open_and_find_option_for(label:, value:)
      raise "The '#{label}'-option is disabled" if option['data-disabled'] == 'true'
      raise "The '#{label}'-option is not selected" unless option_selected?(option, label, option_value)

      perform_option_deselection(option, label, option_value)
      close_if_open
      wait_for_expect { expect(selected?(label, option_value)).to eq false }
      self
    rescue WaitUtil::TimeoutError, Selenium::WebDriver::Error::StaleElementReferenceError
      attempts += 1
      retry if attempts < 3
      raise
    end
  end

  def select_option(label: nil, value: nil)
    select_option_value(label: label, value: value)
    self
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end

  def select_option_value(label: nil, value: nil, wait_for_selection: true)
    raise "No 'label' or 'value' given" if label.nil? && value.nil?

    selector = select_option_selector(label: label, value: value)
    debug_log do
      "select_option_value selector=#{base_selector} " \
        "option_selector=#{selector} label=#{label.inspect} value=#{value.inspect}"
    end
    wait_for_option(selector)
    option = find_option_element(selector, label)
    debug_log do
      "option_element selector=#{base_selector} " \
        "data-value=#{option['data-value'].inspect} " \
        "data-disabled=#{option['data-disabled'].inspect} " \
        "data-selected=#{option['data-selected'].inspect}"
    end

    raise "The '#{label}'-option is disabled" if option['data-disabled'] == 'true'

    option_value = option['data-value']
    perform_option_selection(option, label, option_value, wait_for_selection:)

    option_value
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end

  def value
    wait_for_and_find("#{base_selector} [data-class='current-selected'] input[type='hidden']", visible: false)[:value]
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end

  def wait_for_label(expected_label)
    wait_for_expect do
      expect(label_matches?(expected_label)).to eq true
    end
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

  def selected?(label, value)
    return false unless label || value

    return true if label_matches?(label)
    return true if value_matches?(value)

    label_matches_selected_value?(label)
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end

  def wait_for_value(expected_value)
    wait_for_selector(
      "#{base_selector} [data-class='current-selected'] input[type='hidden'][value='#{expected_value}']",
      visible: false
    )
    self
  end

private

  def raise_if_value_already_selected(label, value)
    return if value.nil?

    current_value = value_no_wait
    return unless current_value == value

    raise "The '#{label || value}'-option is already selected"
  end

  def raise_if_label_already_selected(label, value)
    return if label.nil? || !value.nil?

    current_label = label_no_wait
    return if current_label == label
    return if current_label

    current_value = value_no_wait
    return if current_value.nil? || current_value == ""

    selected_label = selected_label_for_value(current_value)
    return unless selected_label == label

    raise "The '#{label}'-option is already selected"
  end

  def value_matches?(value)
    return false unless value

    scope.page.has_selector?(current_value_selector(value), visible: false, wait: 0)
  end

  def label_matches_selected_value?(label)
    return false unless label

    current_label = label_no_wait
    return current_label == label if current_label

    current_value = value_no_wait
    return false if current_value.nil? || current_value == ""

    selected_label_for_value(current_value) == label
  end

  def select_option_selector(label:, value:)
    if value
      "#{select_option_container_selector}[data-value='#{value}']"
    else
      selector = "#{options_selector} [data-testid='option-presentation']"
      selector << "[data-text='#{label}']" unless label.nil?
      selector
    end
  end

  def wait_for_option(selector)
    wait_for_selector(selector, visible: :all)
  end

  def open_and_find_option_for(label:, value:)
    open
    selector = select_option_selector(label: label, value: value)
    wait_for_option(selector)
    option = find_option_element(selector, label)
    option_value = option['data-value']
    [option, option_value]
  end

  def perform_option_deselection(option, label, option_value)
    click_option_element(option)
    return unless option_selected?(option, label, option_value)

    option_text = option.first("[data-testid='option-presentation-text']", minimum: 0)
    click_option_element(option_text) if option_text
    return unless option_selected?(option, label, option_value)

    option_presentation = option.all("[data-testid='option-presentation']", minimum: 0).first
    click_option_element(option_presentation) if option_presentation
    return unless option_selected?(option, label, option_value)

    click_option_element(option)
  end

  def wait_for_selected_value_or_label(label, value, allow_blank: false)
    value_input_selector = "#{base_selector} [data-class='current-selected'] input[type='hidden']"

    if scope.page.has_selector?(value_input_selector, visible: false, wait: 0)
      return wait_for_selector(current_value_selector(value), visible: false) if value
      return wait_for_selector(current_value_selector(""), visible: false) if allow_blank
    end

    wait_for_expect do
      expect(
        selected_value_or_label_matches?(
          label:,
          value:,
          allow_blank:,
          value_input_selector:
        )
      ).to eq true
    end
  end

  def search_for_option(label)
    return unless scope.page.has_selector?(search_input_selector, wait: 0)

    search(label)
  end

  def options_container_updated?(search_term, previous_text)
    return false unless scope.page.has_selector?(no_options_selector, wait: 0)
    return false unless search_input_value == search_term
    return false if previous_text.nil?

    options_container_text != previous_text
  end

  def options_container_text
    scope.page.find(options_selector).text
  rescue Capybara::ElementNotFound
    nil
  end

  def search_input_value
    scope.page.find(search_input_selector).value
  rescue Capybara::ElementNotFound
    nil
  end

  def search_terms_for(label)
    terms = [label]
    terms << label.split(" (", 2).first if label.include?(" (")
    terms.uniq
  end

  def close_if_open
    return if scope.page.has_no_selector?(options_selector, visible: :all, wait: 0)

    close_attempts = 0

    while scope.page.has_selector?(options_selector, visible: :all, wait: 0) && close_attempts < 3
      close_attempt
      break if wait_for_close?

      close_attempts += 1
    end

    return if scope.page.has_no_selector?(options_selector, visible: :all, wait: 0)

    body = wait_for_and_find("body")
    body.send_keys(:escape)
    return if wait_for_close?

    click_element_safely(body)
    wait_for_close?
  end

  def wait_for_close?
    scope.page.has_no_selector?(options_selector, visible: :all, wait: 1)
  end

  def search_input_selector
    "#{base_selector} [data-class='search-text-input']"
  end

  def click_open_target_element
    target_selector =
      if scope.page.has_selector?(select_container_selector, wait: 0)
        select_container_selector
      elsif scope.page.has_selector?(current_selected_selector, wait: 0)
        current_selected_selector
      else
        base_selector
      end

    element = wait_for_and_find(target_selector)
    scope.page.execute_script(
      "arguments[0].scrollIntoView({block: 'center', inline: 'center'})",
      element
    )
    click_element_safely(element)
  end

  def current_selected_selector
    "#{base_selector} [data-class='current-selected']"
  end

  def wait_for_open
    wait_for_selector(options_selector, visible: :all)
  end

  def click_element_safely(element)
    element.click
  rescue Selenium::WebDriver::Error::ElementClickInterceptedError
    scope.page.driver.browser.action.move_to(element.native).click.perform
  end

  def close_attempt
    close_search_input
    send_close_escape
    click_close_target
  end

  def send_escape
    scope.page.driver.browser.action.send_keys(:escape).perform
  rescue Selenium::WebDriver::Error::InvalidElementStateError
    scope.page.find("body").send_keys(:escape)
  end

  def close_search_input
    return unless scope.page.has_selector?(search_input_selector, wait: 0)

    search_input = wait_for_and_find(search_input_selector)
    click_element_safely(search_input)
    search_input.send_keys(:escape)
    search_input.send_keys(:tab)
  end

  def send_close_escape
    select_container = scope.page.first(select_container_selector, minimum: 0)
    return select_container.send_keys(:escape) if select_container

    send_escape
  end

  def click_close_target
    close_target = scope.page.first(
      "[data-component='super-admin--layout'], " \
      "[data-component='admin/layout'], " \
      "[data-component='layout/base'], " \
      ".react-root > *",
      minimum: 0
    )
    close_target ||= wait_for_and_find("body")
    scope.page.driver.browser.action.move_to(close_target.native).click.perform
  end

  def current_option_label_selectors
    [
      "#{base_selector} [data-class='current-selected'] [data-testid='option-presentation-text']",
      "#{base_selector} [data-class='current-selected'] [data-class='current-option']"
    ]
  end

  def label_matches?(label)
    return false unless label
    return true if scope.page.has_selector?(
      "#{base_selector} [data-class='current-selected'] [data-testid='option-presentation'][data-text='#{label}']",
      wait: 0
    )

    current_option_label_selectors.any? do |selector|
      scope.page.has_selector?(selector, exact_text: label, wait: 0)
    end
  end

  def current_value_selector(value)
    "#{base_selector} [data-class='current-selected'] input[type='hidden'][value='#{value}']"
  end

  def no_options_selector
    "#{options_selector} [data-class='no-options-container']"
  end

  def select_container_selector
    "#{base_selector} [data-class='select-container']"
  end

  def option_label_selector
    "#{options_selector} [data-testid='option-presentation-text']"
  end

  def option_present?(selector, label)
    scope.page.has_selector?(selector, visible: :all, wait: 0) ||
      scope.page.has_selector?(option_label_selector, text: label, visible: :all, wait: 0)
  end

  def find_option_element(selector, label)
    return wait_for_and_find(selector) unless label

    return wait_for_and_find(selector) if selector.start_with?(select_option_container_selector)

    if selector.include?("option-presentation")
      option_presentation = wait_for_and_find(selector)
      return option_presentation.find(:xpath, "./ancestor::*[@data-class='select-option']")
    end

    return wait_for_and_find(selector) if scope.page.has_selector?(selector, wait: 0)

    option_text = wait_for_and_find(option_label_selector, text: label)
    option_text.find(:xpath, "./ancestor::*[@data-class='select-option']")
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end

  def option_selected?(option, label, option_value)
    option['data-selected'] == 'true' || selected?(label, option_value)
  end

  def click_target_element(click_target)
    unless click_target.visible?
      scope.page.execute_script(
        "arguments[0].scrollIntoView({block: 'center', inline: 'center'})",
        click_target
      )
    end

    click_element_safely(click_target)
  end

  def click_option_element(element)
    raise ArgumentError, "Expected a clickable option element, got nil" if element.nil?

    begin
      element.native.location_once_scrolled_into_view
    rescue Selenium::WebDriver::Error::ElementNotInteractableError
      nil
    end

    element.click
  end

  def perform_option_selection(option, label, option_value, wait_for_selection: true)
    debug_log do
      "perform_option_selection selector=#{base_selector} " \
        "label=#{label.inspect} option_value=#{option_value.inspect} " \
        "data-selected=#{option['data-selected'].inspect} wait_for_selection=#{wait_for_selection}"
    end
    click_option_element(option)
    wait_for_selected_value_or_label(label, option_value) if wait_for_selection
  end

  def select_option_container_selector
    "#{options_selector} [data-class='select-option']"
  end

  def select_value_and_close(label:, value:)
    previous_value = value
    debug_log { "open selector=#{base_selector}" }
    open
    selected_value = select_option_value(label:, value:, wait_for_selection: false)
    debug_log do
      "select_option_value selector=#{base_selector} selected_value=#{selected_value.inspect}"
    end
    selected_value = "" if selected_value.nil? && value.nil?
    allow_blank = previous_value == selected_value
    debug_log { "close_if_open selector=#{base_selector}" }
    close_if_open
    [selected_value, allow_blank]
  end

  def wait_for_selected_after_select(label, value, selected_value, allow_blank)
    expected_value = value || selected_value
    debug_log do
      "wait_for_selected_value_or_label selector=#{base_selector} " \
        "label=#{label.inspect} value=#{expected_value.inspect} allow_blank=#{allow_blank}"
    end
    wait_for_selected_value_or_label(label, expected_value, allow_blank:)
  end

  def debug_log(&)
    return unless debug

    Rails.logger.debug { "[haya_select] #{yield}" }
  end

  def selected_value_or_label_matches?(label:, value:, allow_blank:, value_input_selector:)
    has_value_input = scope.page.has_selector?(value_input_selector, visible: false, wait: 0)
    value_matches = current_value_matches?(value)
    blank_matches = blank_value_matches?(allow_blank)
    selected_option_matches = selected_option_matches?(value)
    label_matches = label && label_matches?(label)
    return value_matches || label_matches || selected_option_matches || blank_matches if has_value_input

    label_matches || value_matches || selected_option_matches || blank_matches
  end

  def current_value_matches?(value)
    value && scope.page.has_selector?(current_value_selector(value), visible: false, wait: 0)
  end

  def selected_option_matches?(value)
    return false unless value

    scope.page.has_selector?(
      "#{select_option_container_selector}[data-value='#{value}'][data-selected='true']",
      visible: :all,
      wait: 0
    )
  end

  def blank_value_matches?(allow_blank)
    allow_blank && scope.page.has_selector?(current_value_selector(""), visible: false, wait: 0)
  end

  # rubocop:enable Metrics/ClassLength, Style/Documentation
end

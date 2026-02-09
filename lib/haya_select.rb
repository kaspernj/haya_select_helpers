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
    attempts = 0

    begin
      click_open_target
      wait_for_open
      self
    rescue WaitUtil::TimeoutError, Selenium::WebDriver::Error::StaleElementReferenceError
      attempts += 1
      send_open_key
      retry if attempts < 3
      raise
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

  def select(label = nil, value: nil)
    attempts = 0

    begin
      previous_value = value
      open
      selected_value = select_option_value(label:, value:)
      selected_value = "" if selected_value.nil? && value.nil?
      allow_blank = previous_value == selected_value
      close_if_open
      wait_for_selected_value_or_label(label, value || selected_value, allow_blank:)
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

  def select_option_value(label: nil, value: nil)
    raise "No 'label' or 'value' given" if label.nil? && value.nil?

    selector = select_option_selector(label: label, value: value)
    wait_for_option(selector, label)
    option = find_option_element(selector, label)
    click_target = option_click_target(option)

    raise "The '#{label}'-option is disabled" if option['data-disabled'] == 'true'

    option_value = option['data-value']
    click_target_element(click_target)
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

  def wait_for_value(expected_value)
    wait_for_selector(
      "#{base_selector} [data-class='current-selected'] input[type='hidden'][value='#{expected_value}']",
      visible: false
    )
    self
  end

private

  def select_option_selector(label:, value:)
    if value
      "#{select_option_container_selector}[data-value='#{value}']"
    else
      selector = "#{options_selector} [data-testid='option-presentation']"
      selector << "[data-text='#{label}']" unless label.nil?
      selector
    end
  end

  # rubocop:disable Metrics/AbcSize
  def wait_for_option(selector, label)
    return wait_for_browser { scope.page.has_selector?(selector, visible: :all) } unless label

    return if option_present?(selector, label)

    if scope.page.has_selector?(options_selector, visible: :all)
      wait_for_browser do
        scope.page.has_selector?("#{options_selector} [data-class='select-option']", visible: :all) ||
          scope.page.has_selector?(no_options_selector, visible: :all)
      end
    end

    wait_for_browser do
      option_present?(selector, label)
    end

    return if option_present?(selector, label)

    return unless scope.page.has_selector?(search_input_selector)

    search_terms_for(label).each do |search_term|
      current_options_text = options_container_text
      search_for_option(search_term)

      wait_for_browser do
        option_present?(selector, label) || options_container_updated?(search_term, current_options_text)
      end

      break if option_present?(selector, label)
    end

    wait_for_browser do
      option_present?(selector, label)
    end
  end
  # rubocop:enable Metrics/AbcSize

  def wait_for_selected_value_or_label(label, value, allow_blank: false)
    wait_for_expect do
      value_input_selector = "#{base_selector} [data-class='current-selected'] input[type='hidden']"
      has_value_input = scope.page.has_selector?(value_input_selector, visible: false)
      label_matches = label && label_matches?(label)
      value_matches = value && scope.page.has_selector?(current_value_selector(value), visible: false)
      blank_matches = allow_blank && scope.page.has_selector?(current_value_selector(""), visible: false)

      matches =
        if has_value_input
          value_matches || blank_matches
        else
          label_matches || value_matches || blank_matches
        end

      expect(matches).to eq true
    end
  end

  def selected?(label, value)
    return false unless label || value

    label_matches = label && label_matches?(label)
    value_matches = value && scope.page.has_selector?(current_value_selector(value), visible: false)

    label_matches || value_matches
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end

  def search_for_option(label)
    return unless scope.page.has_selector?(search_input_selector)

    search(label)
  end

  def options_container_updated?(search_term, previous_text)
    return false unless scope.page.has_selector?(no_options_selector)
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
    return if scope.page.has_no_selector?(options_selector, visible: :all)

    close_attempts = 0

    while scope.page.has_selector?(options_selector, visible: :all) && close_attempts < 3
      close_attempt
      break if wait_for_close

      close_attempts += 1
    end

    return if scope.page.has_no_selector?(options_selector, visible: :all)

    body = wait_for_and_find("body")
    body.send_keys(:escape)
    wait_for_close
  end

  def wait_for_close
    wait_for_browser { scope.page.has_no_selector?(options_selector, visible: :all) }
    true
  rescue WaitUtil::TimeoutError
    false
  end

  def search_input_selector
    "#{base_selector} [data-class='search-text-input']"
  end

  def click_open_target
    target_selector =
      if scope.page.has_selector?(select_container_selector)
        select_container_selector
      elsif scope.page.has_selector?(current_selected_selector)
        current_selected_selector
      else
        base_selector
      end

    element = wait_for_and_find(target_selector)
    scope.page.execute_script("arguments[0].focus()", element)
    scope.page.execute_script(
      "arguments[0].scrollIntoView({block: 'center', inline: 'center'})",
      element
    )
    click_element_safely(element)

    return if scope.page.has_selector?(opened_current_selected_selector)

    dispatch_open_events(element)
  end

  def current_selected_selector
    "#{base_selector} [data-class='current-selected']"
  end

  def wait_for_open
    wait_for_browser do
      scope.page.has_selector?(options_selector, visible: :all)
    end
  end

  def click_element_safely(element)
    element.click
  rescue Selenium::WebDriver::Error::ElementClickInterceptedError
    scope.page.driver.browser.action.move_to(element.native).click.perform
  end

  def close_attempt
    close_search_input
    click_close_target
    send_escape
  end

  def send_escape
    scope.page.driver.browser.action.send_keys(:escape).perform
  rescue Selenium::WebDriver::Error::InvalidElementStateError
    scope.page.find("body").send_keys(:escape)
  end

  def close_search_input
    return unless scope.page.has_selector?(search_input_selector)

    search_input = wait_for_and_find(search_input_selector)
    click_element_safely(search_input)
    search_input.send_keys(:escape)
    search_input.send_keys(:tab)
  end

  def click_close_target
    click_element_safely(wait_for_and_find(select_container_selector)) if scope.page.has_selector?(select_container_selector)

    close_target = scope.page.first(
      "[data-component='super-admin--layout'], " \
      "[data-component='admin/layout'], " \
      "[data-component='layout/base'], " \
      ".react-root > *",
      minimum: 0
    )
    close_target ||= wait_for_and_find("body")
    scope.page.driver.browser.action.move_to(close_target.native, 0, 0).click.perform
  end

  def send_open_key
    return unless scope.page.has_selector?(select_container_selector)

    select_container = wait_for_and_find(select_container_selector)
    select_container.send_keys(:enter)
    select_container.send_keys(:space)
  end

  def dispatch_open_events(element)
    scope.page.execute_script(
      <<~JS,
        const target = arguments[0]
        const events = [
          new PointerEvent('pointerdown', {bubbles: true, cancelable: true}),
          new MouseEvent('mousedown', {bubbles: true, cancelable: true}),
          new PointerEvent('pointerup', {bubbles: true, cancelable: true}),
          new MouseEvent('mouseup', {bubbles: true, cancelable: true}),
          new MouseEvent('click', {bubbles: true, cancelable: true})
        ]

        for (const event of events) target.dispatchEvent(event)
      JS
      element
    )
  end

  def current_option_label_selectors
    [
      "#{base_selector} [data-class='current-selected'] [data-testid='option-presentation-text']",
      "#{base_selector} [data-class='current-selected'] [data-class='current-option']"
    ]
  end

  def label_matches?(label)
    current_option_label_selectors.any? do |selector|
      scope.page.has_selector?(selector, exact_text: label)
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
    scope.page.has_selector?(selector, visible: :all) ||
      scope.page.has_selector?(option_label_selector, text: label, visible: :all)
  end

  def find_option_element(selector, label)
    return wait_for_and_find(selector, visible: :all) unless label

    return wait_for_and_find(selector, visible: :all) if selector.start_with?(select_option_container_selector)

    return wait_for_and_find(selector, visible: :all) if scope.page.has_selector?(selector, visible: :all)

    option_text = wait_for_and_find(option_label_selector, text: label, visible: :all)
    option_text.find(:xpath, "./ancestor::*[@data-class='select-option']")
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end

  def option_click_target(option)
    option
  end

  def click_target_element(click_target)
    if click_target.visible?
      click_element_safely(click_target)
    else
      scope.page.execute_script(
        "arguments[0].scrollIntoView({block: 'center', inline: 'center'})",
        click_target
      )
      scope.page.driver.browser.action.move_to(click_target.native).click.perform
    end
  end

  def select_option_container_selector
    "#{options_selector} [data-class='select-option']"
  end

  # rubocop:enable Metrics/ClassLength, Style/Documentation
end

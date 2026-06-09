require "rails_helper"

describe "dummy app haya-select routes" do
  it "shows the React router home page" do
    visit "/"

    expect(page).to have_text("Haya Select Dummy App")
    expect(page).to have_text("React Router Routes")
    expect(page).to have_link("haya-select", href: "/haya-select")
    expect(page).to have_link("haya-select delayed", href: "/haya-select/delayed")
  end

  it "loads each route with the expected package version" do
    [
      ["/haya-select", "1.0.120", "fruit_select"],
      ["/haya-select/delayed", "1.0.120", "fruit_select_delayed"]
    ].each do |path, version, select_id|
      visit path

      expect(page).to have_css("[data-testid='haya-select-version']", text: "Installed package version: #{version}")
      expect(page).to have_css("[data-component='haya-select'][data-id='#{select_id}']")
    end
  end

  it "can select an option with haya-select" do
    visit "/haya-select"

    find("[data-component='haya-select'][data-id='fruit_select'] [data-testid='haya-select/select-container']").click
    expect(page).to have_css("[data-testid='haya-select/options-container'][data-id='fruit_select']", visible: :all)
    find(
      "[data-testid='haya-select/options-container'][data-id='fruit_select'] [data-testid='haya-select/option-presentation'][data-text='Banana']",
      visible: :all
    ).click

    expect(page).to have_css(
      "[data-component='haya-select'][data-id='fruit_select'] [data-testid='haya-select/current-option'] [data-text='Banana'][data-value='banana']"
    )
  end

  it "does not raise when reading value before hidden input mounts" do
    visit "/haya-select/delayed"

    helper_scope = Struct.new(:page).new(page)
    helper = HayaSelect.new(id: "fruit_select_delayed", scope: helper_scope)

    expect { helper.__send__(:value_no_wait) }.not_to raise_error
    expect(helper.__send__(:value_no_wait)).to be_nil
  end
end

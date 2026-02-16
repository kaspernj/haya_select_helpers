require "rails_helper"

RSpec.describe "dummy app haya-select routes" do
  it "shows the React router home page" do
    visit "/"

    expect(page).to have_text("Haya Select Dummy App")
    expect(page).to have_text("React Router Routes")
    expect(page).to have_link("haya-select 1.0.92", href: "/haya-select/v092")
    expect(page).to have_link("haya-select 1.0.94", href: "/haya-select/v094")
    expect(page).to have_link("haya-select 1.0.96", href: "/haya-select/v096")
    expect(page).to have_link("haya-select 1.0.96 delayed", href: "/haya-select/v096-delayed")
  end

  it "loads each route with the expected package version" do
    [
      ["/haya-select/v092", "1.0.92", "fruit_select_v092"],
      ["/haya-select/v094", "1.0.94", "fruit_select_v094"],
      ["/haya-select/v096", "1.0.96", "fruit_select_v096"],
      ["/haya-select/v096-delayed", "1.0.96", "fruit_select_v096_delayed"]
    ].each do |path, version, select_id|
      visit path

      expect(page).to have_css("[data-testid='haya-select-version']", text: "Installed package version: #{version}")
      expect(page).to have_css("[data-component='haya-select'][data-id='#{select_id}']")
    end
  end

  it "can select an option with haya-select in the v1.0.96 route" do
    visit "/haya-select/v096"

    find("[data-component='haya-select'][data-id='fruit_select_v096'] [data-class='current-selected']").click
    find("[data-class='options-container'][data-id='fruit_select_v096'] [data-testid='option-presentation'][data-text='Banana']").click

    expect(page).to have_css(
      "[data-component='haya-select'][data-id='fruit_select_v096'] [data-class='current-option'] [data-text='Banana'][data-value='banana']"
    )
  end

  it "does not raise when reading value before hidden input mounts" do
    visit "/haya-select/v096-delayed"

    helper_scope = Struct.new(:page).new(page)
    helper = HayaSelect.new(id: "fruit_select_v096_delayed", scope: helper_scope)

    expect { helper.__send__(:value_no_wait) }.not_to raise_error
    expect(helper.__send__(:value_no_wait)).to be_nil
  end
end

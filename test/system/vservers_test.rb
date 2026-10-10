require "application_system_test_case"

class VserversTest < ApplicationSystemTestCase
  setup do
    admin = create(:user, :admin)
    visit new_session_path
    fill_in "email_address", with: admin.email_address
    fill_in "password", with: admin.password
    click_button "Sign In"

    @vserver = create(:vserver)
  end

  test "visiting the index" do
    visit vservers_url
    assert_selector "h1", text: "VPS List"
  end

  test "should create vserver" do
    visit vservers_url
    assert_text "VPS List"
    click_on "New VPS"

    check "Enabled" if @vserver.enabled
    fill_in "Healthcheck", with: @vserver.healthcheck
    fill_in "Host", with: @vserver.host
    fill_in "Local path", with: @vserver.local_path
    fill_in "Name", with: @vserver.name
    fill_in "Port", with: @vserver.port
    fill_in "Username", with: @vserver.username
    click_on "Create Vserver"

    assert_text "VPS record was successfully created"
    assert_text "VPS List"
  end

  test "should update Vserver" do
    visit vservers_url
    click_on "Edit", match: :first

    check "Enabled" if @vserver.enabled
    fill_in "Healthcheck", with: @vserver.healthcheck
    fill_in "Host", with: @vserver.host
    fill_in "Local path", with: @vserver.local_path
    fill_in "Name", with: @vserver.name
    fill_in "Port", with: @vserver.port
    fill_in "Username", with: @vserver.username
    click_on "Update Vserver"

    assert_text "VPS record was successfully updated"
    assert_selector "h1", text: "VPS List"
  end

  test "should destroy Vserver" do
    visit status_vserver_path(@vserver)
    click_on "Destroy", match: :first

    assert_text "VPS record was successfully destroyed"
    assert_selector "h1", text: "VPS List"
  end
end

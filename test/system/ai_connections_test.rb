require "application_system_test_case"

class AiConnectionsTest < ApplicationSystemTestCase
  setup do
    admin = create(:user, :admin)
    visit new_session_path
    fill_in "email_address", with: admin.email_address
    fill_in "password", with: admin.password
    click_button "Sign In"

    @ai_model = create(:ai_model)
    @ai_connection = create(:ai_connection)
  end

  test "visiting the index" do
    visit ai_connections_url
    assert_selector "h1", text: "AI Connections"
  end

  test "should create ai connection" do
    visit ai_connections_url
    click_on "New AI Connection"

    fill_in "Name", with: "A new connection"
    select 'Anthropic', from: "Provider"
    fill_in "Api key", with: "api_key_sample"
    select @ai_model.external_id, from: "model_id"
    click_on "Create Ai connection"

    assert_text "Ai connection was successfully created"
  end

  test "should update Ai connection" do
    visit ai_connections_url
    click_on "Edit", match: :first

    fill_in "Api key", with: 'new_api_key'
    fill_in "Name", with: 'new_connection_name'
    click_on "Update Ai connection"

    assert_text "Ai connection was successfully updated"
  end

  test "should destroy Ai connection" do
    visit ai_connections_url
    click_on "Destroy", match: :first

    assert_text "Ai connection was successfully destroyed"
  end
end

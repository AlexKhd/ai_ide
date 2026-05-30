require "application_system_test_case"

class AiConnectionsTest < ApplicationSystemTestCase
  setup do
    @ai_connection = ai_connections(:one)
    @ai_model = ai_models(:one)
  end

  test "visiting the index" do
    visit ai_connections_url
    assert_selector "h1", text: "AI Connections"
  end

  test "should create ai connection" do
    visit ai_connections_url
    click_on "New AI Connection"

    fill_in "Api key", with: @ai_connection.api_key
    select @ai_connection.ai_model.external_id, from: "model_id"
    fill_in "Name", with: "A new connection"
    select 'Anthropic', from: "Provider"
    click_on "Create Ai connection"

    assert_text "Ai connection was successfully created"
    click_on "Home"
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

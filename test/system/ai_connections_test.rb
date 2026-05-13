require "application_system_test_case"

class AiConnectionsTest < ApplicationSystemTestCase
  setup do
    @ai_connection = ai_connections(:one)
  end

  test "visiting the index" do
    visit ai_connections_url
    assert_selector "h1", text: "Ai connections"
  end

  test "should create ai connection" do
    visit ai_connections_url
    click_on "New ai connection"

    fill_in "Api key", with: @ai_connection.api_key
    fill_in "Model", with: @ai_connection.model
    fill_in "Name", with: @ai_connection.name
    fill_in "Provider", with: @ai_connection.provider
    click_on "Create Ai connection"

    assert_text "Ai connection was successfully created"
    click_on "Back"
  end

  test "should update Ai connection" do
    visit ai_connection_url(@ai_connection)
    click_on "Edit this ai connection", match: :first

    fill_in "Api key", with: @ai_connection.api_key
    fill_in "Model", with: @ai_connection.model
    fill_in "Name", with: @ai_connection.name
    fill_in "Provider", with: @ai_connection.provider
    click_on "Update Ai connection"

    assert_text "Ai connection was successfully updated"
    click_on "Back"
  end

  test "should destroy Ai connection" do
    visit ai_connection_url(@ai_connection)
    click_on "Destroy this ai connection", match: :first

    assert_text "Ai connection was successfully destroyed"
  end
end

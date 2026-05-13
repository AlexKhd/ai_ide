require "test_helper"

class AiConnectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ai_connection = ai_connections(:one)
  end

  test "should get index" do
    get ai_connections_url
    assert_response :success
  end

  test "should get new" do
    get new_ai_connection_url
    assert_response :success
  end

  test "should create ai_connection" do
    assert_difference("AiConnection.count") do
      post ai_connections_url, params: { ai_connection: { api_key: @ai_connection.api_key, model: @ai_connection.model, name: @ai_connection.name, provider: @ai_connection.provider } }
    end

    assert_redirected_to ai_connection_url(AiConnection.last)
  end

  test "should show ai_connection" do
    get ai_connection_url(@ai_connection)
    assert_response :success
  end

  test "should get edit" do
    get edit_ai_connection_url(@ai_connection)
    assert_response :success
  end

  test "should update ai_connection" do
    patch ai_connection_url(@ai_connection), params: { ai_connection: { api_key: @ai_connection.api_key, model: @ai_connection.model, name: @ai_connection.name, provider: @ai_connection.provider } }
    assert_redirected_to ai_connection_url(@ai_connection)
  end

  test "should destroy ai_connection" do
    assert_difference("AiConnection.count", -1) do
      delete ai_connection_url(@ai_connection)
    end

    assert_redirected_to ai_connections_url
  end
end

require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)

    post session_url, params: {
      email_address: @user.email_address,
      password: "password"
    }
  end

  test "should get index" do
    get home_index_url
    assert_response :success
  end
end

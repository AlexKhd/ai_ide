require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)

    post session_url, params: {
      email_address: @admin.email_address,
      password: @admin.password
    }
  end

  test "should get index" do
    get home_index_url
    assert_response :success
  end
end

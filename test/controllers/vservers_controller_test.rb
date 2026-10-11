require "test_helper"

class VserversControllerTest < ActionDispatch::IntegrationTest
  setup do
    @vserver = create(:vserver)
    @admin = create(:user, :admin)

    post session_url, params: {
      email_address: @admin.email_address,
      password: @admin.password
    }
  end

  test "should get index" do
    get vservers_url
    assert_response :success
  end

  test "should get new" do
    get new_vserver_url
    assert_response :success
  end

  test "should create vserver" do
    assert_difference("Vserver.count") do
      post vservers_url, params: { vserver: { enabled: @vserver.enabled, healthcheck: @vserver.healthcheck, host: @vserver.host, local_path: @vserver.local_path, name: @vserver.name, port: @vserver.port, username: @vserver.username } }
    end

    assert_redirected_to vservers_url
  end

  test "should show vserver status" do
    get status_vserver_path(@vserver)
    assert_response :success
  end

  test "should get edit" do
    get edit_vserver_url(@vserver)
    assert_response :success
  end

  test "should update vserver" do
    patch vserver_url(@vserver), params: { vserver: { enabled: @vserver.enabled, healthcheck: @vserver.healthcheck, host: @vserver.host, local_path: @vserver.local_path, name: @vserver.name, port: @vserver.port, username: @vserver.username } }
    assert_redirected_to vservers_url
  end

  test "should destroy vserver" do
    assert_difference("Vserver.count", -1) do
      delete vserver_url(@vserver)
    end

    assert_redirected_to vservers_url
  end
end

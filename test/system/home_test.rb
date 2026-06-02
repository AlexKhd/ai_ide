require "application_system_test_case"

class HomeTest < ApplicationSystemTestCase
  test 'redirect to login unless logged in' do
    visit '/home/index'
    assert_selector "h1", text: "Sign In"
  end

  test "visiting the index" do
    user = create(:user, :admin)

    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: user.password
    click_button "Sign In"

    assert_selector "h2", text: "Welcome"

    visit '/home/index'
    assert_selector "#navbar", text: "AI IDE"
    assert_selector "#ai-output", text: "The answer is here.."

    click_on "Ask AI"
    assert_selector "#ai-output", text: "Thinking.."
  end
end

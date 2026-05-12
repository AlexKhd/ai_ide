require "application_system_test_case"

class HomeTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit '/home/index'
    assert_selector "#navbar", text: "AI IDE"

    click_on "Ask AI"
    assert_selector "#ai-output", text: "You typed"
  end
end

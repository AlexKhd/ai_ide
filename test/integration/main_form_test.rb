require "test_helper"

class MainFormTest < ActionDispatch::IntegrationTest

  test "Main page elements" do
    skip 'skipped'
    get "/home/index"
    assert_dom "#navbar p", "AI IDE"
    assert_dom "button#ask-ai", "Ask AI"
  end

  test "Get response" do
    skip 'skipped'
    get "/home/index"
    assert_dom "#navbar p", "AI IDE"

    post "/ai/code_suggest",
      params: {"code" => "'Hi AI IDE!'", "ai" => {"code" => "// Write your Ruby code here\nputs 'Hello AI IDE!'"}
    }

    assert_response :success
  end
end

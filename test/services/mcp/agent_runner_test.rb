require "test_helper"

class AgentRunnerTest < ActiveSupport::TestCase
  test "constants defined" do
    assert_equal 15, Mcp::AgentRunner::MAX_DEPTH
  end
end

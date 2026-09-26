require "test_helper"

class AgentRunnerTest < ActiveSupport::TestCase
  test "MAX_DEPTH constant is defined" do
    assert_equal 15, Mcp::AgentRunner::MAX_DEPTH
  end

  test "max_depth option can be customized on initialization" do
    ai_model = create(:ai_model)
    ai_connection = create(:ai_connection, ai_model: ai_model)
    ai_session = create(:ai_session, ai_connection: ai_connection, ai_model: ai_model)

    runner = Mcp::AgentRunner.new(ai_session, max_depth: 5)
    assert_equal 5, runner.instance_variable_get(:@max_depth)
  end
end

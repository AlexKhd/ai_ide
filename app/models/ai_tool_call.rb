class AiToolCall < ApplicationRecord
  belongs_to :ai_message
  belongs_to :mcp_tool
end

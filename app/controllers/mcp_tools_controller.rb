class McpToolsController < ApplicationController
  before_action :set_mcp_tool, only: [:toggle]

  def index
    @mcp_tools = McpTool.order(:name)
  end

  # PATCH /mcp_tools/:id/toggle
  def toggle
    @mcp_tool.toggle!(:enabled)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "mcp_tool_#{@mcp_tool.id}",
          partial: "mcp_tools/mcp_tool",
          locals: { tool: @mcp_tool }
        )
      end
      format.html { redirect_to mcp_tools_path, notice: "Tool configuration updated successfully." }
    end
  end

  private

  def set_mcp_tool
    @mcp_tool = McpTool.find(params[:id])
  end
end

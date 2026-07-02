# app/services/mcp/tool_registry.rb
module Mcp
  class ToolRegistry
    TOOL_MAP = {
      "file_read"  => Mcp::Tools::FileReadTool,
      "file_write" => Mcp::Tools::FileWriteTool,
      "ai_search"  => Mcp::Tools::SearchTool
    }.freeze

    def self.fetch(name)
      TOOL_MAP[name]
    end

    def self.enabled_names
      ::McpTool.where(enabled: true).pluck(:name)
    end

    def self.definitions_for_llm
      enabled_names.map do |name|
        tool_class = fetch(name)
        next unless tool_class.respond_to?(:definition)

        # Cohere strict requirement: Enforce function type wrapper shape explicitly
        raw_def = tool_class.definition
        if raw_def.key?(:type) || raw_def.key?("type")
          raw_def
        else
          {
            type: "function",
            function: raw_def
          }
        end
      end.compact
    end
  end
end

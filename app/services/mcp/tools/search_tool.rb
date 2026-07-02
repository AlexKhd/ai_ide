# app/services/mcp/tools/search_tool.rb
module Mcp
  module Tools
    class SearchTool < BaseTool
      def self.definition
        {
          type: "function",
          function: {
            name: "ai_search",
            description: "Searches the project codebase for specific queries, files, or text patterns.",
            parameters: {
              type: "object",
              properties: {
                query: {
                  type: "string",
                  description: "The term, class name, method, or code pattern to search for."
                }
              },
              required: ["query"]
            }
          }
        }
      end

      def call
        query = input["query"]
        return failure("Missing query") unless query

        # placeholder logic
        success({
          query: query,
          results: [
            "Result 1 for #{query}",
            "Result 2 for #{query}"
          ]
        })
      end
    end
  end
end

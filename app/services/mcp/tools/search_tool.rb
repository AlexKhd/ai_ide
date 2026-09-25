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
        return failure("Missing query") if query.blank?

        root_dir = Rails.root.to_s
        matched_files = []

        # Real codebase search across text files
        Dir.glob("#{root_dir}/**/*.{rb,html,slim,js,json,yml,md,txt}").each do |full_path|
          relative_path = full_path.sub("#{root_dir}/", "")
          next unless Mcp::Security.safe_path?(relative_path)

          # Check path match
          if File.basename(full_path).downcase.include?(query.downcase) || relative_path.downcase.include?(query.downcase)
            matched_files << relative_path
            next
          end

          # Check content match
          begin
            content = File.read(full_path)
            if content.downcase.include?(query.downcase)
              matched_files << relative_path
            end
          rescue
            # Skip unreadable/binary files
          end
        end

        success({
          query: query,
          results: matched_files.first(20)
        })
      rescue => e
        failure("Search failed: #{e.message}")
      end
    end
  end
end

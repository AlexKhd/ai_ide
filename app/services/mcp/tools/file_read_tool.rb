# app/services/mcp/tools/file_read_tool.rb
module Mcp
  module Tools
    class FileReadTool < BaseTool
      def self.definition
        {
          type: "function",
          function: {
            name: "file_read",
            description: "Reads the complete contents of a specific file inside the project directory.",
            parameters: {
              type: "object",
              properties: {
                path: {
                  type: "string",
                  description: "The relative path to the file from the project root (e.g., 'app/models/user.rb')."
                }
              },
              required: ["path"]
            }
          }
        }
      end

      def call
        path = input["path"]
        return failure("Missing file path parameter") if path.blank?

        unless Mcp::Security.safe_path?(path)
          return failure("Access denied. This file path contains protected or restricted system configurations.")
        end

        root_dir = Rails.root.to_s
        full_path = File.expand_path(path, root_dir)

        unless full_path.start_with?(root_dir)
          return failure("Access denied. Cannot read outside project directory.")
        end

        if File.directory?(full_path)
          return failure("Path is a directory, not a file.")
        end

        if File.exist?(full_path)
          success({ path: path, content: File.read(full_path) })
        else
          failure("File not found at path: #{path}")
        end
      rescue => e
        failure("Error reading file: #{e.message}")
      end
    end
  end
end

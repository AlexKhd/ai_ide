# app/services/mcp/tools/file_write_tool.rb
module Mcp
  module Tools
    class FileWriteTool < BaseTool
      def self.definition
        {
          type: "function",
          function: {
            name: "file_write",
            description: "Creates a new file or completely overwrites an existing file with fresh content inside the project directory.",
            parameters: {
              type: "object",
              properties: {
                path: {
                  type: "string",
                  description: "The relative path to the file from the project root (e.g., 'app/models/post.rb')."
                },
                content: {
                  type: "string",
                  description: "The full, exact file content code to be written into the destination target path."
                }
              },
              required: ["path", "content"]
            }
          }
        }
      end

      def call
        path = input["path"]
        content = input["content"]

        return failure("Missing file path parameter.") if path.blank?
        return failure("Missing content data body.") if content.nil?

        # Strict security constraint: Lock file writing down to project layout framework bounds
        root_dir = Rails.root.to_s
        full_path = File.expand_path(path, root_dir)

        unless full_path.start_with?(root_dir)
          return failure("Access denied. Cannot create or modify files outside the project directory root context.")
        end

        # Ensure directory paths exist recursively before saving code payloads down
        FileUtils.mkdir_p(File.dirname(full_path))

        # Write content over target file position
        File.write(full_path, content)

        success({
          path: path,
          status: "File written successfully.",
          bytes_written: content.bytesize
        })
      rescue => e
        failure("Error executing file write: #{e.message}")
      end
    end
  end
end

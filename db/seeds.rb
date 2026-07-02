# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
if User.count.zero?
  User.create!(
    email_address: Rails.application.credentials.dig(:admin, :email),
    nickname: :admin,
    password: Rails.application.credentials.dig(:admin, :password),
    password_confirmation: Rails.application.credentials.dig(:admin, :password),
    role: :admin
  )
end

puts "Seeding MCP Tools..."

tools_to_seed = [
  {
    name: "file_read",
    description: "Reads the complete contents of a specific file inside the project directory.",
    schema: Mcp::Tools::FileReadTool.definition
  },
  {
    name: "file_write", # 👈 Add this block to your array
    description: "Creates a new file or completely overwrites an existing file with fresh content inside the project directory.",
    schema: Mcp::Tools::FileWriteTool.definition
  },
  {
    name: "ai_search",
    description: "Searches the project codebase for specific queries or patterns.",
    schema: Mcp::Tools::SearchTool.definition
  }
  # Future tools
]

tools_to_seed.each do |tool_data|
  tool = McpTool.find_or_initialize_by(name: tool_data[:name])
  tool.update!(
    description: tool_data[:description],
    schema: tool_data[:schema],
    enabled: true # Turn them on by default
  )
  puts "Registered/Updated tool: #{tool.name}"
end

puts "MCP Tools seeding completed successfully!"

class McpTool < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  scope :enabled, -> { where(enabled: true) }

  # Decodes/parses the schema if it's stored as JSON
  def parsed_schema
    schema.is_a?(String) ? JSON.parse(schema) : schema
  end
end

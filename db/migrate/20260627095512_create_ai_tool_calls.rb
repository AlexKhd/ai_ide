class CreateAiToolCalls < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_tool_calls do |t|
      t.references :ai_message, null: false, foreign_key: true
      t.references :mcp_tool, null: false, foreign_key: true

      t.string :status  # pending, success, failed

      t.json :input
      t.json :output
      t.text :error

      t.integer :duration_ms

      t.timestamps
    end

    add_index :ai_tool_calls, :status
    add_index :ai_tool_calls, [:ai_message_id, :created_at]
  end
end

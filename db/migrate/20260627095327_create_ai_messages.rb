class CreateAiMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_messages do |t|
      t.references :ai_session, null: false, foreign_key: true

      t.string :role, null: false  # user, assistant, system, tool
      t.text :content

      t.string :name
      t.string :tool_call_id

      t.json :metadata

      t.timestamps
    end

    add_index :ai_messages, :role
    add_index :ai_messages, :tool_call_id
    add_index :ai_messages, [:ai_session_id, :created_at]
  end
end

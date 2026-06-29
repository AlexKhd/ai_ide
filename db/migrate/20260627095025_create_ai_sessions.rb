class CreateAiSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :ai_model, null: false, foreign_key: true
      t.references :ai_connection, foreign_key: true

      t.string :title
      t.text :system_prompt

      t.float :temperature
      t.integer :max_tokens

      t.boolean :active, default: true, null: false
      t.datetime :last_message_at

      t.timestamps
    end

    add_index :ai_sessions, [:user_id, :active]
  end
end

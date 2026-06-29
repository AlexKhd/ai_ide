class CreateMcpTools < ActiveRecord::Migration[8.0]
  def change
    create_table :mcp_tools do |t|
      t.string :name, null: false
      t.text :description

      t.json :schema
      t.boolean :enabled, default: true, null: false

      t.integer :timeout_ms
      t.string :handler_type
      t.json :handler_config

      t.timestamps
    end

    add_index :mcp_tools, :name, unique: true
    add_index :mcp_tools, :enabled
  end
end

class AddActiveToAiConnections < ActiveRecord::Migration[8.0]
  def change
    add_column :ai_connections, :active, :boolean, default: false, null: false
  end
end

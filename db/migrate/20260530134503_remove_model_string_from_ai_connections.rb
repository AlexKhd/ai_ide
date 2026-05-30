class RemoveModelStringFromAiConnections < ActiveRecord::Migration[8.0]
  def change
    remove_column :ai_connections, :model, :string
  end
end

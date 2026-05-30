class AddModelIdToAiConnections < ActiveRecord::Migration[8.0]
  def change
    add_column :ai_connections, :model_id, :bigint
    add_foreign_key :ai_connections, :ai_models, column: :model_id
  end
end

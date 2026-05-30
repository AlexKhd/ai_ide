class RemoveAiConnectionIdFromAiModels < ActiveRecord::Migration[8.0]
  def change
    remove_index :ai_models, [:ai_connection_id, :external_id]
    remove_foreign_key :ai_models, :ai_connections
    remove_column :ai_models, :ai_connection_id, :bigint

    add_index :ai_models, :external_id, unique: true
  end
end

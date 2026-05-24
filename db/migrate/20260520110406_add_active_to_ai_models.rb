class AddActiveToAiModels < ActiveRecord::Migration[8.0]
  def change
    add_column :ai_models, :active, :boolean, default: true, null: false
    add_index :ai_models, :active
  end
end

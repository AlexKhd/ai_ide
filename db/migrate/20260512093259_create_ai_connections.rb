class CreateAiConnections < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_connections do |t|
      t.string :name
      t.string :provider
      t.string :api_key
      t.string :model

      t.timestamps
    end
  end
end

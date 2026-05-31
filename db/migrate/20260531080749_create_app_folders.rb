class CreateAppFolders < ActiveRecord::Migration[8.0]
  def change
    create_table :app_folders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :path, null: false
      t.text :description
      t.string :language
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :app_folders, [:user_id, :path], unique: true
  end
end

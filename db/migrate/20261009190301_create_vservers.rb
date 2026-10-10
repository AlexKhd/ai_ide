class CreateVservers < ActiveRecord::Migration[8.0]
  def change
    create_table :vservers do |t|
      t.string :name
      t.string :host
      t.string :healthcheck
      t.integer :port
      t.string :username
      t.string :local_path
      t.boolean :enabled

      t.timestamps
    end
  end
end

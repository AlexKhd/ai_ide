class CreateDeployments < ActiveRecord::Migration[8.0]
  def change
    create_table :deployments do |t|
      t.references :vserver, null: false, foreign_key: true
      t.string :status
      t.datetime :started_at
      t.datetime :finished_at
      t.string :commit_sha
      t.text :output

      t.timestamps
    end
  end
end

class AddStatusToVservers < ActiveRecord::Migration[8.0]
  def change
    add_column :vservers, :server_status, :string
    add_column :vservers, :app_status, :string
    add_column :vservers, :last_checked_at, :datetime
  end
end

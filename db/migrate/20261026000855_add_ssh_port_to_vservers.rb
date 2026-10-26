class AddSshPortToVservers < ActiveRecord::Migration[8.1]
  def change
    add_column :vservers, :ssh_port, :integer, null: false, default: 22
  end
end

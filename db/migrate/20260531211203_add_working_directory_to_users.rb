class AddWorkingDirectoryToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :working_directory, :string, default: nil
  end
end

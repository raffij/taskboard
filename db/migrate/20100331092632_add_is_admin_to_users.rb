class AddIsAdminToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :is_admin, :bool
    execute "update users set is_admin = 1 where editor = 1"
  end

  def self.down
    remove_column :users, :is_admin
  end
end

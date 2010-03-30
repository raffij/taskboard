class GiveExistingUsersPermissionToEveryTaskboard < ActiveRecord::Migration
  def self.up
    execute "insert into permissions (user_id, taskboard_id, created_at, updated_at) " +
      "select u.id, t.id, CURDATE(), CURDATE() " +
      "from users u cross join taskboards t"
  end

  def self.down
  end
end

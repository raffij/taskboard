class DefaultCardPointsAre0 < ActiveRecord::Migration
  def self.up
    change_column_default "cards", "points", 0
  end

  def self.down
    change_column_default "cards", "points", 2 
  end
end

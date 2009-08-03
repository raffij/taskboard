class AddPointsToCards < ActiveRecord::Migration
  def self.up
    add_column :cards, :points, :integer, :default => 0
  end

  def self.down
    remove_column :cards, :points
  end
end

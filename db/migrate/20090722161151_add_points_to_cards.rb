class AddPointsToCards < ActiveRecord::Migration
  def self.up
    add_column :cards, :points, :integer, :default => 2
  end

  def self.down
    remove_column :cards, :points
  end
end

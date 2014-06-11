class AddMaxIndexToRounds < ActiveRecord::Migration
  def change
    add_column :rounds, :max_qo_index, :integer, default: 0
  end
end

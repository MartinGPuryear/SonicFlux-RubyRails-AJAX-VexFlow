class AddDefaultValuesToRounds < ActiveRecord::Migration
  def change
    change_column :rounds, :num_participants, :integer, default: 0
    change_column :rounds, :difficulty_level, :integer, default: 0

    change_column :results, :num_correct, :integer, default: 0
    change_column :results, :num_skipped, :integer, default: 0
    change_column :results, :num_incorrect, :integer, default: 0
    change_column :results, :points, :integer, default: 0
    change_column :results, :round_complete, :boolean, default: true
  end
end

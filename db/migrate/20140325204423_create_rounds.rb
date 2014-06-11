class CreateRounds < ActiveRecord::Migration
  def change
    create_table :rounds do |t|
      t.integer :num_participants
      t.integer :difficulty_level

      t.timestamps
    end
  end
end

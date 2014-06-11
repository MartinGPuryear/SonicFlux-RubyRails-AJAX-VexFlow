class CreateResults < ActiveRecord::Migration
  def change
    create_table :results do |t|
      t.integer :num_correct
      t.integer :num_skipped
      t.integer :num_incorrect
      t.integer :points
      t.integer :rank
      t.boolean :was_complete_round

      t.references :round, index: true
      t.references :user, index: true

      t.timestamps
    end
  end
end

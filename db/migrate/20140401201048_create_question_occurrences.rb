class CreateQuestionOccurrences < ActiveRecord::Migration
  def change
    create_table :question_occurrences do |t|
      t.references :round, index: true
      t.references :question, index: true
      t.integer :question_index_in_round

      t.timestamps
    end

    drop_table   :question_occurences
    
  end
end

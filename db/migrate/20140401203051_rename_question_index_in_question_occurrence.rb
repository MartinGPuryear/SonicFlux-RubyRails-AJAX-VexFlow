class RenameQuestionIndexInQuestionOccurrence < ActiveRecord::Migration
  def change
  	rename_column :question_occurrences, :question_index_in_round, :index_in_round
  end
end

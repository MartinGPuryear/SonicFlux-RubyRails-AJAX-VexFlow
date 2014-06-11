class RenameChoiceTypeIDs < ActiveRecord::Migration
  def change
  	rename_column :questions, :question_types_id, :question_type_id
    change_table :questions do |t|
  		t.rename_index  :index_questions_on_question_types_id, :index_questions_on_question_type_id
  	end
  end
end

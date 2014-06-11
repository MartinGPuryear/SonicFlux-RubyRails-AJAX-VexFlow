class AddQuestionTypeRemovePromptToQuestion < ActiveRecord::Migration
  def change
    change_table :questions do |t|
      t.remove :prompt, :question_type
      t.references :question_types, index: true
    end
  end
end

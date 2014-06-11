class RemoveChoiceFromQuestions < ActiveRecord::Migration
  def change
  	remove_column :questions, :choice_id, :integer
  end
end

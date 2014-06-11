class AddIndexsToQuestion < ActiveRecord::Migration
  def change
  	add_index :questions, :correct_choice_id
  	add_index :questions, :close_choice_id
  end
end

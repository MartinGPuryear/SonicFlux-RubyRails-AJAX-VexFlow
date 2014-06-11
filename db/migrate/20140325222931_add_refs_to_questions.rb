class AddRefsToQuestions < ActiveRecord::Migration
	def change
		add_column :questions, :correct_choice_id, :integer
		add_column :questions, :close_choice_id, :integer
	end
end
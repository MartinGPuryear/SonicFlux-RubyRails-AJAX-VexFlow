class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.integer :question_type
      t.integer :choice_type
      t.integer :difficulty_level
      t.string :prompt
      t.string :content

      t.references :choice, index: true

      t.timestamps
    end
  end
end

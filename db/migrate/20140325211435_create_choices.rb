class CreateChoices < ActiveRecord::Migration
  def change
    create_table :choices do |t|
      t.integer :choice_type
      t.string :prompt
      t.string :content

      t.timestamps
    end
  end
end

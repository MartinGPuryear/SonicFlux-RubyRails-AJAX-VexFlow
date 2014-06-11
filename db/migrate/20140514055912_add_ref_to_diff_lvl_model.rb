class AddRefToDiffLvlModel < ActiveRecord::Migration
  def change
    change_table :questions do |t|
      t.references :difficulty_level, index: true
    end
    change_table :users do |u|
      u.references :difficulty_level, index: true
    end
    change_table :rounds do |u|
      u.references :difficulty_level, index: true
    end
  end
end

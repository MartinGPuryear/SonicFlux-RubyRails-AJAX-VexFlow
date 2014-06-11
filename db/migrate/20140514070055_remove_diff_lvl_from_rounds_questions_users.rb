class RemoveDiffLvlFromRoundsQuestionsUsers < ActiveRecord::Migration
  def change
    change_table :questions do |q|
      q.remove :difficulty_level
    end
    change_table :rounds do |r|
      r.remove :difficulty_level
    end
    change_table :users do |u|
      u.remove :difficulty_level
    end
  end
end

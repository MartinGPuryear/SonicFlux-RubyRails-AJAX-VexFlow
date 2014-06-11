class Question < ActiveRecord::Base

  belongs_to  :difficulty_level
  belongs_to  :question_type
  belongs_to  :correct_choice,        class_name: "Choice"
  belongs_to  :close_choice,          class_name: "Choice"
  
  has_many    :question_occurrences,  dependent:  :destroy

  validates   :content,               presence:   true
  validates   :choice_type,           presence:   true
  validates   :correct_choice_id,     presence:   true
  
end


class QuestionType < ActiveRecord::Base

  has_many  :questions,   dependent:  :destroy

  validates :prompt,      presence:   true

end

class Choice < ActiveRecord::Base

  has_many  :correct_questions, class_name: "Question", dependent:  :destroy,
                                                        foreign_key: "correct_choice_id" 

  has_many  :close_questions,   class_name: "Question", dependent: :destroy,
                                                        foreign_key: "close_choice_id"
  validates :choice_type,       presence: true
  validates :prompt,            presence: true

end

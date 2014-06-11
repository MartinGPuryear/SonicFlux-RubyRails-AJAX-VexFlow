class DifficultyLevel < ActiveRecord::Base

  has_many    :users,       dependent:  :destroy
  has_many    :questions,   dependent:  :destroy
  has_many    :rounds,      dependent:  :destroy

  validates   :desc,        presence:   true

end

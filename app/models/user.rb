class User < ActiveRecord::Base

  belongs_to :difficulty_level
  validates  :difficulty_level_id, presence:     true

  has_many   :results,             dependent:    :destroy

  validates  :player_tag,          presence:     true,
                                   length:       { within:  4..24},
                                   uniqueness:   { case_sensitive:   false }

  validates  :password_digest,     presence:     true,
                                   length:       { is:  60},
                                   confirmation: true

  has_secure_password

end

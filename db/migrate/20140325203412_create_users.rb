class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :player_tag
      t.string :password_digest
      t.integer :facebook_id
      t.integer :difficulty_level

      t.timestamps
    end
  end
end

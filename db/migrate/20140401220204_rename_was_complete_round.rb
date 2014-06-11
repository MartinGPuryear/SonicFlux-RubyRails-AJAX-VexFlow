class RenameWasCompleteRound < ActiveRecord::Migration
  def change
  	rename_column :results, :was_complete_round, :round_complete
  end
end

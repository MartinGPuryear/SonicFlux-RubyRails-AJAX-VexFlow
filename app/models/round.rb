class Round < ActiveRecord::Base

  belongs_to  :difficulty_level

  has_many    :results,               dependent:  :destroy
  has_many    :question_occurrences,  dependent:  :destroy

  #   class methods
  class << self

    #   Only keep Rounds that have QuestionOccurrences
    def prune_question_occurrence_orphans(rounds_to_ignore)
      rd = select{|d| d.question_occurrences.count == 0} - rounds_to_ignore

      unless rd.empty?
        puts 'Destroying ' + rd.length.to_s + ' Round records without questions'
        rd.each{|d| FIRST_ROOM_NUM.upto(FIRST_ROOM_NUM + NUM_ROOMS - 1) { |r| @@prev_round[r] = nil if @@prev_round[r] == d.id }; d.destroy}
      end
    end

    #   Only keep Rounds that have Results
    def prune_result_orphans(rounds_to_ignore)
      rd = select{|d| d.results.count == 0} - rounds_to_ignore

      unless rd.empty?
        puts 'Destroying ' + rd.length.to_s + ' Round records without Results'
        rd.each{|d| d.destroy}
      end
    end

    #   Recalculate any clearly incorrect Round.num_participants
    def recalculate_incorrect_num_participants(rounds_to_ignore)
      rd = select{|d| d.num_participants != d.results.select{|t| t.round_complete}.count} - rounds_to_ignore
     
      unless rd.empty?
        puts 'Updating ' + rd.length.to_s + ' Round records where num_participants != # of round_complete Results'
        rd.each{|d| d.update(num_participants: d.results.select{|t| t.round_complete}.count)}
      end
      return rd
    end

    #   Recalculate any clearly incorrect Round.max_qo_index
    def recalculate_incorrect_max_qo_index(rounds_to_ignore)

      edRd = []
      #   Each Round's max_qo_index cannot be nil 
      rd = select{|r| r.max_qo_index == nil} - rounds_to_ignore
      edRd += rd

      unless rd.empty?
        puts 'Updating ' + rd.length.to_s + ' Round records where max_qo_index is nil (simply setting to 0)'
        rd.each{|d| d.update(max_qo_index: 0)}
      end

      #   Set each Round's max_qo_index to the max (corr+skip+incorr) from any Result
      rd = select{|r| r.max_qo_index != r.results.collect{|t| t.num_correct + t.num_skipped + t.num_incorrect}.max} - rounds_to_ignore
      edRd += rd
      
      unless rd.empty?
        puts 'Updating ' + rd.length.to_s + ' Round records where max_qo_index != the largest num answers from attached Result records'
        rd.each{|d| d.update(max_qo_index: d.results.collect{|t| t.num_correct + t.num_skipped + t.num_incorrect}.max)}
      end
      return edRd
    end

  end

end

class QuestionOccurrence < ActiveRecord::Base

  belongs_to :round
  belongs_to :question
  
  class << self   # Class methods

    #   Only keep QuestionOccurrences that have Questions
    def prune_question_orphans(qo_to_ignore)
      qo = select{|o| !o.question} - qo_to_ignore
      if qo.length > 0
        puts "Destroying #{ qo.length } QuestionOccurrence records without a Question"
        qo.each{|o| o.destroy}
      end
    end

    #   Only keep QuestionOccurrences that have Rounds
    def prune_round_orphans(qo_to_ignore)
      qo = select{|o| !o.round} - qo_to_ignore
      if qo.length > 0
        puts "Destroying #{ qo.length } QuestionOccurrence records without a Round"
        qo.each{|o| o.destroy}
      end
    end

    #   Only keep QuestionOccurrences reached in that Round 
    def prune_unreached_questions(qo_to_ignore)
      qo = select{|o| o.index_in_round > o.round.max_qo_index} - qo_to_ignore
      if qo.length > 0
        puts "Destroying #{ qo.length } QuestionOccurrence records that were never reached in their round"
        qo.each{|o| o.destroy}
      end
    end

  end

end

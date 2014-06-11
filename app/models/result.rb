class Result < ActiveRecord::Base

  belongs_to  :round
  belongs_to  :user

  #   Class methods
  class << self
    
    #   Only keep Results that have at least 1 corr/skip/incorr
    def prune_unanswered(results_to_ignore)
      rt = select{|t| t.num_correct+t.num_skipped+t.num_incorrect == 0} - results_to_ignore

      unless rt.empty?
        puts 'Destroying ' + rt.length.to_s + ' Result records without answers'
        rt.each{|t| t.destroy}
      end
    end

    #   Only keep Results that have Users
    def prune_user_orphans(results_to_ignore)
      rt = select{|t| !t.user} - results_to_ignore

      unless rt.empty?
        puts 'Destroying ' + rt.length.to_s + ' Result records without a User'
        rt.each{|t| t.destroy}
      end
    end

    #   Only keep Results that have Rounds
    def prune_round_orphans(results_to_ignore)
      rt = Result.select{|t| !t.round} - results_to_ignore

      unless rt.empty?
        puts 'Destroying ' + rt.length.to_s + ' Result records without a Round'
        rt.each{|t| t.destroy}
      end
    end

    #   for Results, truncate the number of answers if they are higher than MAX_NUM_QUESTIONS
    def recalculate_incorrect_num_answers(results_to_ignore)
      rt = Result.select{|t| t.num_correct+t.num_skipped+t.num_incorrect > MAX_NUM_QUESTIONS } - results_to_ignore

      unless rt.empty?
        rt.each{|t| t.update(num_incorrect: [MAX_NUM_QUESTIONS, t.num_incorrect].min)}
        rt.each{|t| t.update(num_skipped: [MAX_NUM_QUESTIONS - t.num_incorrect, t.num_skipped].min)}
        rt.each{|t| t.update(num_correct: [MAX_NUM_QUESTIONS - t.num_incorrect - t.num_skipped, t.num_correct].min)}
        rt.each{|t| t.update(points: [(t.num_correct * 10) - t.num_skipped - (t.num_incorrect * 5),0].max)}
      end

      return rt
    end

    #   For Results, clear the rank if it is not round_complete
    def unrank_incompletes
      rt = Result.select{|t| !t.round_complete && t.rank }

      unless rt.empty?
        puts 'Updating ' + rt.length.to_s + ' Result records that received ranks, even though they are not round_complete'
        rt.each{|t| t.update(rank:'')}
      end

      return rt
    end
      
    #   Recalculate any clearly incorrrect ranks
    def recalculate_outlier_ranks(results_to_ignore)
      rt1 = select{|t| t.round_complete && t.rank && (t.rank < 1)} - results_to_ignore
      rt2 = select{|t| t.round_complete && t.rank && (t.rank > t.round.num_participants)} - results_to_ignore
      rt3 = select{|t| t.round_complete && !t.rank } - results_to_ignore
      rt = rt1+rt2+rt3

      unless rt.empty?
        rd = rt.collect{|t| t.round}.uniq
        rd.each{|d| calculate_result_ranks(d.id) }
      end

      return rt
      
    end

    def retrieve_my_progress(user_id)
      results = {}
      all_results = Result.where(user_id: user_id)
      all_complete_results_rounds = all_results.joins(:round).where(round_complete: true)
      

      month_start = DateTime.now.at_beginning_of_month
      month_results = year_results.where("results.created_at >= ?", month_start)

      week_start = DateTime.now.at_beginning_of_week
      week_results = month_results.where("results.created_at >= ?", week_start)

      day_start = DateTime.now.at_beginning_of_day
      day_results = week_results.where("results.created_at >= ?", day_start)

      hour_start = DateTime.now.at_beginning_of_hour
      hour_results = day_results.where("results.created_at >= ?", hour_start)

      results['all'] = {}
      results['all']['high'] = all_results.maximum(:points)
      results['all']['avg'] = all_complete_results_rounds.average(:points).round(2)
      best_rank = all_complete_results_rounds.select("rank, num_participants, rank*10000/num_participants as quality").order("quality ASC, num_participants DESC").first
      results['all']['best_numer'] = best_rank.rank
      results['all']['best_denom'] = best_rank.num_participants
      results['all']['avg_numer'] = all_complete_results_rounds.average("rank").round(2)
      results['all']['avg_denom'] = all_complete_results_rounds.average("num_participants").round(2)

      results['all']['points'] = all_results.sum(:points)
      results['all']['top_tens'] = all_complete_results_rounds.where(round_complete: true).where("(rank-1)*10000/num_participants < 1000").count
      results['all']['completes'] = all_complete_results_rounds.count
      results['all']['partials'] = all_results.count - results['all']['completes']

      results['all']['num_correct'] = all_results.sum(:num_correct)
      results['all']['num_skipped'] = all_results.sum(:num_skipped)
      results['all']['num_incorrect'] = all_results.sum(:num_incorrect)

      results['year'] = {}
      year_start = DateTime.now.at_beginning_of_year
      year_results = all_results.
        where("results.created_at >= ?", year_start).
        select("max(points) AS max_points, sum(num_correct) AS num_corr, sum(num_incorrect) AS num_incorr, sum(num_skipped) AS num_skip, sum(points) AS sum_points").
        first

      year_complete_results = all_results.
        joins(:round).
        where("results.created_at >= ?", year_start).
        where(round_complete: true).
        select("avg(num_participants) AS avg_num_participants, avg(points) AS avg_points, avg(rank) AS avg_rank, count(rank) AS count_completes, 
          num_participants, rank*10000/num_participants as quality, rank").
        order("quality ASC, num_participants DESC").
        first

      results['year']['high_score'] = year_results.max_points
      results['year']['avg_score'] = year_complete_results.avg_points.round(2)
      results['year']['best_rank'] = year_complete_results.rank.to_s + 'out of ' + year_complete_results.num_participants.to_s
      results['year']['avg_rank'] = year_complete_results.avg_rank.round(2).to_s + 'out of ' + year_complete_results.avg_num_parts.round(2).to_s

      results['year']['total_points'] = year_results.sum_points
      results['year']['top_ten_percent_rounds'] = year_complete_results.where("(rank-1)*10000/num_participants < 1000").count
      results['year']['complete_rounds'] = year_complete_results.count_completes
      results['year']['partial_rounds'] = year_results.count - results['year']['completes']

      results['year']['total_num_correct'] = year_results.num_corr
      results['year']['total_num_skipped'] = year_results.num_skip
      results['year']['total_num_incorrect'] = year_results.num_incorr

      return results
    end

  end
end

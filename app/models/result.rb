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
      rt = select{|t| !t.round} - results_to_ignore

      unless rt.empty?
        puts 'Destroying ' + rt.length.to_s + ' Result records without a Round'
        rt.each{|t| t.destroy}
      end
    end

    #   for Results, truncate the number of answers if they are higher than MAX_NUM_QUESTIONS
    def recalculate_incorrect_num_answers(results_to_ignore)
      rt = select{|t| t.num_correct+t.num_skipped+t.num_incorrect > MAX_NUM_QUESTIONS } - results_to_ignore

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
      rt = select{|t| !t.round_complete && t.rank }

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
      rt3 = select{|t| t.round_complete && (t.rank.nil? || t.rank == 0) } - results_to_ignore
      rt = rt1+rt2+rt3

      unless rt.empty?
        rd = rt.collect{|t| t.round}.uniq
        rd.each{|d| calculate_result_ranks(d.id) }
      end

      return rt
      
    end

    def retrieve_progress_over_interval(user_id, begin_time)
      interval_results = {}
      interval_results['avg_rank'] = '-'
      interval_results['avg_score'] = '-'
      interval_results['best_rank'] = '-'
      interval_results['complete_rounds'] = 0
      interval_results['high_score'] = '-'
      interval_results['partial_rounds'] = 0
      interval_results['top_ten_percent_rounds'] = 0
      interval_results['total_num_correct'] = 0
      interval_results['total_num_incorrect'] = 0
      interval_results['total_num_skipped'] = 0
      interval_results['total_points'] = 0
      interval_results['total_rounds'] = 0

      base_results = joins(:round).where(user_id: user_id).where("results.created_at >= ?", begin_time) if begin_time
      base_results = joins(:round).where(user_id: user_id) if begin_time.nil?

      if base_results.exists?

        group_results = base_results.
          select("COUNT(user_id) AS count_all_results, MAX(points) AS high_score, SUM(num_correct) AS num_corr, SUM(num_incorrect) AS num_incorr, SUM(num_skipped) AS num_skip, SUM(points) AS sum_points").
          first

        interval_results['total_rounds'] = group_results.count_all_results
        interval_results['high_score'] = group_results.high_score
        interval_results['total_points'] = group_results.sum_points
        interval_results['total_num_correct'] = group_results.num_corr
        interval_results['total_num_skipped'] = group_results.num_skip
        interval_results['total_num_incorrect'] = group_results.num_incorr

        complete_results = base_results.
          where(round_complete: true).
          select("num_participants, points, rank, (rank-1)*10000/num_participants AS quality").
          order("quality ASC, num_participants DESC")

        if complete_results.exists?
          interval_results['best_rank'] = complete_results.first.rank.to_s + ' out of ' + complete_results.first.num_participants.to_s

          complete_group_results = complete_results.
            select("AVG(num_participants) AS avg_num_participants, AVG(points) AS avg_points, AVG(rank) AS avg_rank, COUNT(rank) AS count_complete_results, SUM(CASE WHEN (rank-1)*10000/num_participants < 1000 THEN 1 ELSE 0 END) AS count_top_ten_percent").
            first

          if complete_group_results.count_complete_results > 0
            interval_results['avg_rank'] = complete_group_results.avg_rank.round(2).to_s + ' out of ' + complete_group_results.avg_num_participants.round(2).to_s
            interval_results['avg_score'] = complete_group_results.avg_points.round(2)
            interval_results['complete_rounds'] = complete_group_results.count_complete_results
            interval_results['top_ten_percent_rounds'] = complete_group_results.count_top_ten_percent
          end
          interval_results['partial_rounds'] = group_results.count_all_results - complete_group_results.count_complete_results
        end
      
      end

      return interval_results
    end

    def retrieve_my_progress(user_id)
      results = {}
      
      results['hour']  = retrieve_progress_over_interval(user_id, DateTime.now.at_beginning_of_hour)
      results['day']   = retrieve_progress_over_interval(user_id, DateTime.now.at_beginning_of_day)
      results['week']  = retrieve_progress_over_interval(user_id, DateTime.now.at_beginning_of_week)
      results['month'] = retrieve_progress_over_interval(user_id, DateTime.now.at_beginning_of_month)
      results['year']  = retrieve_progress_over_interval(user_id, DateTime.now.at_beginning_of_year)
      results['all']   = retrieve_progress_over_interval(user_id, nil)

      return results
    end

    def retrieve_leaders(begin_time)
      results = {}

      interval_results =  joins(:user).where("results.created_at >= ?", begin_time).
                          select("player_tag, avg(points) AS avg, max(points) AS max, sum(points) AS sum").
                          group(:user_id) if begin_time
      interval_results =  joins(:user).
                          select("player_tag, avg(points) AS avg, max(points) AS max, sum(points) AS sum").
                          group(:user_id) if begin_time.nil?

      if interval_results.exists?
        results['avg'] = interval_results.where(round_complete: true).order("avg(points) DESC").limit(NUM_LEADERS_TO_DISPLAY)
        results['max'] = interval_results.order("max(points) DESC").limit(NUM_LEADERS_TO_DISPLAY)
        results['sum'] = interval_results.order("sum(points) DESC").limit(NUM_LEADERS_TO_DISPLAY)
      else
        results['avg'] = results['max'] = results['sum'] = []
      end

      return results
    end

  end
end

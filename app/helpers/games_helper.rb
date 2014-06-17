
module GamesHelper

  #   Constants used across various controllers
    NUM_LEADERS_TO_DISPLAY = 5
    MAX_NUM_QUESTIONS = 80

    FIRST_ROOM_NUM = 0
    NUM_ROOMS = 4

    CHOICE_ID_SKIP = -1
    POINTS_FOR_SKIP = -1
    POINTS_FOR_INCORRECT = -5
    POINTS_FOR_CORRECT = 10

  #   State variables used across various controllers
    @@round_in_progress ||= false

    @@clientList ||= Array.new(FIRST_ROOM_NUM + NUM_ROOMS) { |rm| Array.new() }

    @@prev_round ||= Array.new(FIRST_ROOM_NUM + NUM_ROOMS) { |rm| nil }
    @@curr_round ||= Array.new(FIRST_ROOM_NUM + NUM_ROOMS) { |rm| nil }
    @@next_round ||= Array.new(FIRST_ROOM_NUM + NUM_ROOMS) { |rm| nil }

    FIRST_ROOM_NUM.upto(FIRST_ROOM_NUM + NUM_ROOMS - 1) { |room|
          @@prev_round[room] ||= @@curr_round[room] ||= @@next_round[room] ||= nil
          @@clientList[room] ||= Array.new()
      }

    puts "Done with init code at GamesHelper() *****************************************************************************"    

  #   One-time setup code, run when the server starts up.
    # Called from environment.rb, after SonicFlux::Application.initialize!
  def run_startup_code
    puts 'run_startup_code() ***********************************************************************************************'
    dump_round_vars

    # Initialize the array of rounds and clients, and prepare the first set of questions
    @@round_in_progress ||= false

    @@clientList ||= Array.new(FIRST_ROOM_NUM + NUM_ROOMS) { |rm| Array.new() }

    @@prev_round ||= Array.new(FIRST_ROOM_NUM + NUM_ROOMS) { |rm| nil }
    @@curr_round ||= Array.new(FIRST_ROOM_NUM + NUM_ROOMS) { |rm| nil }
    @@next_round ||= Array.new(FIRST_ROOM_NUM + NUM_ROOMS) { |rm| nil }

    FIRST_ROOM_NUM.upto(FIRST_ROOM_NUM + NUM_ROOMS - 1) { |room| 
          @@prev_round[room] ||= @@curr_round[room] ||= @@next_round[room] ||= nil
          @@clientList[room] ||= Array.new()
          prepare_round(room) 
      }
    dump_round_vars
    puts "Done with init code (phase I) at run_startup_code() **************************************************************"

    # Delete orphaned records (numerous types), fix malformed/incomplete ones
    do_housecleaning
    dump_round_vars
    puts "Done with init code (phase II) at run_startup_code() **************************************************************"
  end

  #   Console-dump various state variables, along with passed-in strings
    # These include our 'waterwheel' round arrays (what was, is, will be)
    # as well as the list of clients in each room.
  def dump_round_vars(before_str=nil, after_str=nil)
    puts before_str
    puts "This is prev_round:        #{ @@prev_round.to_s }"
    puts "This is curr_round:        #{ @@curr_round.to_s }"
    puts "This is next_round:        #{ @@next_round.to_s }"

    FIRST_ROOM_NUM.upto(FIRST_ROOM_NUM + NUM_ROOMS - 1) { |room| 
      puts "Room[#{room}]: #{@@clientList[room]}"
    }
    puts after_str
  end

  #   Create a round & question set, if next_round[room] isn't already set.
  #   Account for when the round is already underway, as well.
  def prepare_round(diff_lvl)
    dump_round_vars "Entering prepare_round(#{diff_lvl}), @@round_in_progress= #{ @@round_in_progress }"

    round_id = nil
    round_id = @@curr_round[diff_lvl] if @@round_in_progress == true
    round_id = @@next_round[diff_lvl] if round_id.nil?

    if (round_id == nil)
      round = Round.new(difficulty_level_id: diff_lvl)
      round.save

      if (@@round_in_progress == true)
        @@curr_round[diff_lvl] = round.id
      else
        @@next_round[diff_lvl] = round.id
      end

      create_question_set(round.id)

      # if !MODE_0, send Q+C's to all in room, for quick use later
      # if so, need to create the non-close incorrect choices as well!!
    end

    dump_round_vars "", 'Exiting prepare_round()'
  end

  #   Did the round have any questions answered? (if not, we'll reuse it)
  def round_had_activity(round_id)
    return false if (round_id == 0 || round_id.nil?)

    round_results = Result.all.where("round_id = ?",round_id)
    round_answers = round_results.reduce(0){ |answers,rt| answers + rt.num_correct + rt.num_skipped + rt.num_incorrect}
    return (round_answers > 0)
  end

  #   Create a set of questions for this round. Some may already exist
    # How could some (but not all) question_occurrences already be there?
    # Specifically, the case where the last person leaves a room mid-round,
    # (hence the round is finalized), then someone rejoins the room. 
  def create_question_set(round_id)
    puts 'Entering create_question_set()'
    diff_lvl = Round.find(round_id).difficulty_level_id

    existing_qo_set = QuestionOccurrence.where(round_id: round_id)
    last_qo_index = existing_qo_set.length

    if (last_qo_index < MAX_NUM_QUESTIONS)
      puts "Creating #{MAX_NUM_QUESTIONS - last_qo_index} QO objects for round #{round_id}"
      existing_questions = existing_qo_set.map{|qo| qo.question}
      question_pool = Question.where("difficulty_level_id = ?", diff_lvl).shuffle - existing_questions
      question_pool.first(MAX_NUM_QUESTIONS - last_qo_index).each{|q| last_qo_index += 1; qo=QuestionOccurrence.new(round_id: round_id, question_id: q.id, index_in_round: last_qo_index); qo.save; }
    else
      puts 'No need to create additional QO objects'
    end
    puts 'Exiting create_question_set()'
  end

  #   Before next round, pre-create Result records for gamers in this room.
  def create_next_round_results(room)
    if (@@curr_round[room] == nil)          #   if @@curr_round exists, another client already started us
      puts "create_next_round_results() for room #{room}"
      @@clientList[room].each { |user_id| 
        if (Result.where(round_id: @@next_round[room]).where(user_id: user_id).length > 0)
          puts "Result already exists for this client & round..."
        else
          Result.new(round_id: @@next_round[room], user_id: user_id, round_complete: true).save
          puts "created new result for user #{user_id}"
        end
      }
    end
  end

  #   When round is over, set final results and prune unused records.
    # Set the number of gamers that completed the entire round (used
    # in rankings - specifically the '8' in "3 out of "8"). 
    # Delete any unviewed questions from the set, and Results where 
    # no questions were answered. 
    # Set rankings (e.g. the '3' in "3 out of 8"). 
    # If there were NO results for the round, delete it.
  def finalize_round(round_id)
    dump_round_vars 'Entering finalize_round()'
    
    num_gamers_complete_round = Result.all.where(round_complete: true).where("round_id = ?",round_id).count
    Round.find(round_id).update(num_participants: num_gamers_complete_round)
    
    prune_question_set(round_id)
    prune_results(round_id)
    calculate_result_ranks(round_id)
    round_id = prune_round(round_id)
    
    dump_round_vars '','Exiting finalize_round()'
    return round_id
  end
  
  #   For this round, delete any unviewed questions (question_occurrence).
  def prune_question_set(round_id)
    puts 'Entering prune_question_set()'
    round = Round.find(round_id)
    QuestionOccurrence.where(round_id: round_id).where("index_in_round > ?", round.max_qo_index).each{ |qo| qo.destroy; }
    puts 'Exiting prune_question_set()'
  end

  #   For this round, delete any empty results (no questions answered).
  def prune_results(round_id)
    results = Round.find(round_id).results
      #   Every Result must have at least 1 corr/skip/incorr
    rt = results.select{|t| t.num_correct+t.num_skipped+t.num_incorrect == 0}
    if rt.length > 0
      puts 'Destroying ' + rt.length.to_s + ' Result records without answers'
      rt.each{|t| t.destroy}
    end
  end

  #   For this round, calculate the rankings for 'complete' results.
    # For ONLY round_complete results, sort by point order, then
    # number them incrementally. For ties, each gets the better score.
    # I.e. if 3 results were equal, all receive "1 out of 3".
  def calculate_result_ranks(round_id)
    puts "calculate_result_ranks(#{round_id})"

    rank = 1
    num_ties = 0
    prev_score = -1
    results = Result.all.where(round_complete: true).where("round_id = ?",round_id).order(points: :desc).each{ 
                          |t| 
                            if (t.points == prev_score)
                              num_ties += 1
                            else
                              num_ties = 0
                            end
                            t.update(rank: rank - num_ties); 
                            rank += 1; 
                            prev_score = t.points
                          }
  end

  #   For this round, set num_participants (num of round_complete Results)
  def prune_round(round_id)
    
    return nil if Round.all.where(id:round_id).count==0
    round = Round.find(round_id)

    if (round.num_participants != round.results.select{|t| t.round_complete}.count)
      puts 'Updating a Round record where num_participants != # of round_complete Results'
      round.update(num_participants: round.results.select{|t| t.round_complete}.count)
    end
    return round_id
  end

  #   For this user, get the current round. Assumes Play (not Lobby)
  def get_round_id
    round_id = @@curr_round[public_user.difficulty_level_id]
  end

  #   Return the Nth question from this round's question set.
  def get_question(round_id, round_question_num)
    puts "get_question(#{round_id}, #{round_question_num})"

    question_occurrence = QuestionOccurrence.includes(:question).where("round_id = ? AND index_in_round = ?",round_id, round_question_num).take
    return nil if question_occurrence.nil?

    question = question_occurrence.question
  end

  #   For this question, return the client-safe subset (not correct_choice)
  def get_public_question(question_id)
    puts 'get_public_question()'
    Question.joins(:question_type).select('question_type_id, difficulty_level_id, content, prompt').find(question_id)
  end

  #   Create a struct for this round's Nth question, to pass to client
    # Struct includes the public_question, the N index in the round,
    # and the list of choices for the question.
  def get_question_info(round_id, round_question_num)
    puts "get_question_info(#{round_id}, #{round_question_num})"
    question_info = {}
    question = get_question(get_round_id, round_question_num)
    
    if (!question.nil?)
      question_info[:question] = get_public_question(question.id)
      question_info[:round_question_num] = round_question_num
      question_info[:choices] = get_choices(question)
    end

    return question_info
  end
  
  #   Create and return a list of possible choices for this question.
    # Includes not only the correct choice, but also one considered
    # likely to fool the unwary (plus three random others).
    # The client will also automatically include "Skip" also.
  def get_choices(question)
    puts 'get_choices()'
    choices = Choice.select('id, prompt').find(question.correct_choice_id, question.close_choice_id)
    choices += Choice.select('id, prompt').where.not(id: question.correct_choice_id).where.not(id: question.close_choice_id).where(choice_type:0).shuffle.first(3)
    choices.shuffle!
  end
  
  #   Handle an incoming answer, for the given round, question, and choice
    # Retrieve the round, increment its 'max question reached' if needed.
    # Retrieve the Result (create if necessary, as !round_complete).
    # Depending on Skip, or Correct, or Incorrect, increment the number
    # of that type of answer. Also update points (don't let go below 0).
  def grade_question(round_id, round_question_num, chosen_id)
    dump_round_vars "Entering grade_question(#{round_id}, #{round_question_num}, #{chosen_id})"
    round = Round.find(round_id)
    if (round_question_num > round.max_qo_index)
      round.update(max_qo_index: round_question_num)
    end

    correct_choice = get_question(round_id, round_question_num).correct_choice
    user = current_user
    diff_lvl = user.difficulty_level_id
    puts "user_id: #{user.id}, round_question_num: #{round_question_num}, diff_lvl: #{diff_lvl}, chosen_id: #{chosen_id}"

    result = Result.where("user_id = ?", user.id).where("round_id = ?", round_id).first
    if !result
      result = Result.new(user_id: user.id, round_id: round_id, round_complete: false)
    end

    if chosen_id == CHOICE_ID_SKIP      #   
      puts "Q#{round_question_num} [diff {diff_lvl}]: skipped.  #{correct_choice.id} (#{correct_choice.prompt}) is correct."
      outcome = POINTS_FOR_SKIP
      result.num_skipped += 1      
    elsif chosen_id.to_i == correct_choice.id
      puts "Q#{round_question_num} [diff {diff_lvl}]: #{chosen_id} (#{correct_choice.prompt}).  Correct!!"
      outcome = POINTS_FOR_CORRECT
      result.num_correct += 1      
    else
      puts "Q#{round_question_num} [diff {diff_lvl}]: #{chosen_id} (#{Choice.find(chosen_id).prompt}).  Unfortunately #{correct_choice.id} (#{correct_choice.prompt}) is correct."
      outcome = POINTS_FOR_INCORRECT
      result.num_incorrect += 1      
    end
    result.points = [result.points + outcome, 0].max
    result.save
    dump_round_vars '', 'Exiting grade_question()'
    return {outcome: outcome, points: result.points, correct_id: correct_choice.id, correct_prompt: correct_choice.prompt}
  end
  
  #   On client enter, prep a round if first into a room. Add user to
  #   that room's clientList. Create a Result for this round.
  def client_entered(user_id, room)
    dump_round_vars "Entering client_entered(#{room})"
    if @@clientList[room].empty?
      prepare_round(room)
    end
    @@clientList[room].push(user_id);   # => param[:id])
    
    if (@@round_in_progress == true)
      round_id = @@curr_round[room]
    else      
      round_id = @@next_round[room]
    end
    if (Result.where(round_id: round_id).where(user_id: user_id).length > 0)
      puts 'Result for this client/round already exists - must be a REentry'
    else
      Result.new(round_id: round_id, user_id: user_id, round_complete: !@@round_in_progress).save
    end
    dump_round_vars '', 'Exiting client_entered()'
  end

  #   On client exit, update Result, remove from roomlist, and (if empty) clean room
    # If curr_round is set, then we exited during an active round, so mark that 
    # Result's round_complete as false.  Otherwise, if next_round is set then we 
    # must have exited during lobby time (next_round means 'not yet started') so we 
    # can delete the Result connected with that round. 
    # Remove the user from that room in our clientList.
    # Finally, if the room is now empty, perform any needed cleanup on the room.
  def client_exited(user_id, room)
    dump_round_vars "Entering client_exited(#{room})"
    if (@@curr_round[room] != nil)
      result = Result.where("user_id = ?", user_id).where("round_id = ?", @@curr_round[room]).first
      result.update(round_complete: false) if !result.nil?
    end
    @@clientList[room] -= [user_id]

    if @@clientList[room].empty?      # room is empty, so...
      cleanup_empty_room(room)
    end
    dump_round_vars '', 'Exiting client_exited()'
  end

  #   Room is now empty. Finalize any previous or current round.
  def cleanup_empty_room(room)
    # dump_round_vars 'Entering cleanup_empty_room()'
    # if !@@prev_round[room].nil?
    #   finalize_round(@@prev_round[room])  # ...finalize any previous round
    #   @@prev_round[room] = nil
    # end
    # if !@@curr_round[room].nil?
    #   finalize_round(@@curr_round[room])  # ...finalize any in-progress round
    #   # @@curr_round[room] = nil
    # end
    # dump_round_vars '', 'Exiting cleanup_empty_room()'
  end

  #   User entered the gameplay view - set state vars, call client_entered 
  def set_playing
    puts "set_playing, sess[play]: #{session[:playing]}, current_user:#{current_user}"

    if !signed_in?
      session[:playing] = false
      puts "playing(#{playing}) but not yet signed in... setting to false."
      return
    end

    if !session[:playing]
      puts "current_user.id=#{current_user.id}, diff_lvl_id=#{current_user.difficulty_level_id}"
      client_entered(current_user.id, current_user.difficulty_level_id)
      session[:playing] = true
    end
  end
  
  #   User entered a non-gameplay view - clear state vars, call client_exited 
  def set_not_playing
    puts "set_not_playing(), sess[play]: #{session[:playing]}, current_user:#{current_user}"
    
    session[:playing] = false if session[:playing].nil?
    if !signed_in?
      puts "set_not_playing() but not yet signed in... setting to false."
      return
    end

    if (session[:playing] == true)
      client_exited(current_user.id, current_user.difficulty_level_id)
      session[:playing] = false
    end
  end

  #   Is this user in gameplay (Lobby or Play) right now?
  def playing?
    puts 'playing?()'
    (session[:playing] == true)
  end

  #   Mainly on server start, delete unneeded records and fix malformed ones.
    # Exclude records connected to the current prev_/curr_/next_ rounds. 
  def do_housecleaning
    puts "\n********** Entering do_housecleaning() **********"

    round_ids = (@@prev_round + @@curr_round + @@next_round).compact.uniq
    rounds_to_ignore = round_ids.map{|id| Round.find(id)} if !round_ids.nil?
    qo_to_ignore = QuestionOccurrence.select{|qo| rounds_to_ignore.include?(qo.round)}
    results_to_ignore = Result.select{|rt| rounds_to_ignore.include?(rt.round)}

    oldNumQO = QuestionOccurrence.count
    oldNumRd = Round.count
    oldNumRt = Result.count
    edRd = edRt = []

    #   Only keep QuestionOccurrences that have Questions
    QuestionOccurrence.prune_question_orphans(qo_to_ignore)
    
    #   Only keep QuestionOccurrences that have Rounds
    QuestionOccurrence.prune_round_orphans(qo_to_ignore)

    #   Only keep Results that have at least 1 corr/skip/incorr
    Result.prune_unanswered(results_to_ignore)

    #   Only keep Results that have Users
    Result.prune_user_orphans(results_to_ignore)

    #   Only keep Results that have Rounds
    Result.prune_round_orphans(results_to_ignore)

    #   Only keep Rounds that have QuestionOccurrences
    Round.prune_question_occurrence_orphans(rounds_to_ignore)

    #   Only keep Rounds that have Results
    Round.prune_result_orphans(rounds_to_ignore)

    #   Recalculate any clearly erroneous num_correct, num_skipped, num_incorrect
    edRt += Result.recalculate_incorrect_num_answers(results_to_ignore)

    #   Recalculate any clearly incorrect Round.num_participants
    edRd += Round.recalculate_incorrect_num_participants(rounds_to_ignore)

    #   Recalculate any clearly incorrect Round.max_qo_index
    edRd += Round.recalculate_incorrect_max_qo_index(rounds_to_ignore)

      #   Only keep QuestionOccurrences reached in that Round 
    QuestionOccurrence.prune_unreached_questions(qo_to_ignore)
    
    #   For Results, clear the rank if it is not round_complete
    edRt += Result.unrank_incompletes

    #   Recalculate any clearly incorrrect ranks
    edRt += Result.recalculate_outlier_ranks(results_to_ignore)

    edNumRt = edRt.uniq.length
    edNumRd = edRd.uniq.length

    newNumQO = QuestionOccurrence.count
    newNumRd = Round.count
    newNumRt = Result.count
    puts "Deleted #{oldNumQO-newNumQO} QuestionOccurrences, #{oldNumRd-newNumRd} Rounds, #{oldNumRt-newNumRt} Results"
    puts "Performed #{edNumRd} updates on Rounds, #{edNumRt} updates on Results"
    puts "********** Exiting do_housecleaning() **********\n"
  end

end

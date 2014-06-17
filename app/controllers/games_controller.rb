class GamesController < ApplicationController

  #   GamesController handles all non-signup, non-signin URLs.  
  #   These include the Intro and About views, the Leaderboard
  #   and personal Progress views.
  #
  #   Most significantly, it also handles the Play (and Lobby)
  #   views. In addition to play(), this entails handling the 
  #   "round has started" and "round has ended" events, as
  #   well as serving questions out to clients and handling 
  #   answers coming in from clients.  

  #   TODO: optimize Leaders by doing these queries in the 
  #   model instead of pushing this to the Helper (or View!)

  #   TODO: optimize Progress by doing these queries in the 
  #   model instead of pushing this to the Helper (or View!)

  #   TODO: guest mode - allow guests to take quizes, include 
  #   them in room counts, appear in the gameboard during
  #   and after a round (as "Guest 1" etc).  Only difference
  #   is that Result should not be saved. Also, no Progress 
  #   boards or Profiles are visible.

  before_action :require_signin, only: [:progress, :play]
  before_action :set_not_playing, only: [:intro, :about, :progress, :leaders]
  before_action :set_playing, only: [:play]

  #   Enter gameplay mode. Might currently be Lobby or Play mode.
    # Only @public_user is passed to this view. Via a before_action,
    # the "playing or not" state is changed to "playing". This state
    # is used to determine whether a Result is round_complete, and 
    # whether the gamer is present in the room. 
    # This function currently requires signin, but future work could
    # enable a Guest mode where Result records are simply not saved.  
  def play
    public_user
    render layout: "game_layout"
  end

  #   Notification that a gameplay round has started. 
    # Change our state variable to indicate that it is underway, and
    # (for each room) waterwheel the next_round into curr_round. 
    # Note: currently this notificatin is received from clients, so
    # it might be received mid-round when a client first connects.
    # Also it will be received from each client, so subsequent 
    # notifications after the first should simply be ignored. 
  def round_started
    dump_round_vars 'Entering round_started()'
    if (!@@round_in_progress)
      @@round_in_progress = true
      FIRST_ROOM_NUM.upto(FIRST_ROOM_NUM + NUM_ROOMS - 1) { |room|

        if (@@curr_round[room] == nil)          #   if @@curr_round exists, another client already started us
          prepare_round(room)                   #   set up next_round if it isn't already
          @@curr_round[room] = @@next_round[room]
        end

        @@prev_round[room] = nil
        @@next_round[room] = nil
      }
    end
    dump_round_vars 'Exiting round_started()'
    render json: { round_started_confirm: true }
  end

  #   Notification that a gameplay round has ended.
    # Change our state variable to indicate that it has ended,
    # and (for each room) waterwheel the current round either
    # forward into the prev_round slot (used for backward-
    # looking leaderboard purposes), or back into next_round
    # slot to be reused, if the round has had no activity (if
    # there were no players, or no questions answered). If
    # there WAS activity, then the next round (and set of 
    # questions) is now created, as well as result records
    # for gamers currently in the room.  In either case, 
    # curr_round is cleared & 'round_ended_confirm' returned. 
  def round_ended
    dump_round_vars 'Entering round_ended()'
    @@round_in_progress = false
    
    FIRST_ROOM_NUM.upto(FIRST_ROOM_NUM + NUM_ROOMS - 1) { |room| 

      if !@@curr_round[room].nil?
        if round_had_activity(@@curr_round[room])
          @@prev_round[room] = finalize_round(@@curr_round[room])   #   might be nil instead of a round_id
        else
          @@prev_round[room] = nil
          @@next_round[room] = @@curr_round[room]
        end
      end
      @@curr_round[room] = nil
      prepare_round(room)
      create_next_round_results(room)
    }
    dump_round_vars 'Exiting round_ended()'
    render json: { round_ended_confirm: true }
  end

  #   User requested to change the difficulty level.
    # Change the user profile's difficulty_level_id.
    # remove client from current room, add to new one
    # We expect Node to remove client from old room,
    # add to new one, and broadcast the roomlists.
  def change_difficulty
    user = current_user
    new_lvl = params[:difficulty_level]
    client_exited(user.id, user.difficulty_level_id)
    user.update(difficulty_level_id: new_lvl)
    client_entered(user.id, user.difficulty_level_id)

    change_response = {confirmed: true, new_room: user.difficulty_level_id }
    puts "change_difficulty(), change_response = confirmed:#{change_response[:confirmed]}, new_room:#{change_response[:new_room]}"
    render json: change_response
  end

  #   Return the first question, if round is still underway.
  def first_question
    puts 'Entering first_question()'
    question_info = {}

    if get_round_id.nil?
      puts '  Client asked for a question, even though the round is over.'
      question_info = {question: nil, round_question_num: 0, choices: nil }
    else
      question_info = get_question_info(get_round_id, 1)
    end
    puts 'Exiting first_question()'
    render json: question_info
  end

  #   Handle a submittted answer; return the next question.
    # Get the question info for the next question.
    # Also, grade the answer given by the client for the 
    # current question. Render to client this combined info.
  def answer
    dump_round_vars 'Entering answer()'
    
    round_id = get_round_id
    puts "******** Question to be graded is index[#{params[:round_question_num]}], getting info for next(#{params[:round_question_num].to_i + 1})"

    question_response = get_question_info(round_id, params[:round_question_num].to_i + 1)
    question_response[:answer_info] = grade_question(round_id, params[:round_question_num].to_i, params[:chosen_id].to_i)

    dump_round_vars 'Exiting answer()'
    render json: question_response
  end

  #   Display the introduction box for SonicFlux.
  def intro

    dump_round_vars 'intro()'
  end

  #   Display the About... box for SonicFlux.
  def about

    dump_round_vars 'about()'
  end

  #   Show the progress view for the provided user id.
    # Retrieve the public_user for this user.  Pass it,
    # and all the results for this user, to the view. 
  def progress
    dump_round_vars 'Entering progress()'
    public_user(params[:id])

    results = Result.retrieve_my_progress(params[:id])

    puts results

    @all_results   = results['all']
    @year_results  = results['year']
    @month_results = results['month']
    @week_results  = results['week']
    @day_results   = results['day']
    @hour_results  = results['hour']
  end

  #   Show the historical leaderboard.
    # Pass ALL our historical results, and the number
    # of leaders to display, to the view.  
  def leaders
    dump_round_vars 'Entering leaders()'
    
    @num_leaders = NUM_LEADERS_TO_DISPLAY
    @all_points = Result.retrieve_leaders(nil)
    @year_points = Result.retrieve_leaders(DateTime.now.at_beginning_of_year)
    @month_points = Result.retrieve_leaders(DateTime.now.at_beginning_of_month)
    @week_points = Result.retrieve_leaders(DateTime.now.at_beginning_of_week)
    @day_points = Result.retrieve_leaders(DateTime.now.at_beginning_of_day)
    @hour_points = Result.retrieve_leaders(DateTime.now.at_beginning_of_hour)
  end
end

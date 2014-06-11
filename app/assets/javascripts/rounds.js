// # Place all the behaviors and hooks related to the matching controller here.
// # All this logic will automatically be available in application.js.
// # You can use CoffeeScript in this file: http://coffeescript.org/

var msOffset;
var timeGameOver; 
var timeGameStarts; 
var timeNextChange;
var scoreThisRound = 0;
var inLobby;
var lobbyDuration;
var playDuration;

my_public_profile.points = 0;
my_public_profile.incomplete_round = true;
retainWarningText=false;

difficulty_level_str = ["Beginner", 
                        "Intermediate", 
                        "Advanced", 
                        "Expert" 
                        //, "Deity"
                       ];

// var io = io.connect("http://localhost:6789"); 
// var io = io.connect("http://localhost:6789", {force_connection: true} ); 
// var io = io.connect("http://localhost:6789", {'force new connection': true} ); 

function initialConnect()
{
  console.log('EMIT: client_ready - ', my_public_profile.player_tag);
  
  io.emit('client_ready', {profile: my_public_profile} );
}

function updateDifficultyLevel(new_level)
{
  $('.diff-lvl-btn').removeClass("btn-primary");
  $('#diff-lvl-'+new_level).addClass("btn-primary");

  $('#difficulty-level-display').html(difficulty_level_str[new_level]);
}

function updateCountdownBar(secsRemaining)
{  
  // console.log('updateCountdownBar: ' + secsRemaining + ' secs remaining');
  var timeStr = '' + ('0' + parseInt(secsRemaining / 60)).slice(-1) + ':' + ('00' + (secsRemaining % 60)).slice(-2);
  $('#countdown-bar').html(timeStr);
}

function updatePlayboard(players)
{  
    // console.log('updatePlayboard: playboard = ', players);
    $('#live-leader-table-body').html('');

    for (var index = 0; index < players.length; index++) 
    {
      // console.log('iterating through players: ' + index, players[index]);
      var gamerStr = '<tr><td>' + players[index].player_tag + '</td><td>' + players[index].points + '</td></tr>';
      $('#live-leader-table-body').append(gamerStr);
    }
}

function updateLobbyboard(players)
{  
    console.log('updateLobbyboard: lobbyboard = ', players);

    $('#next-round-table-body').html('');

    for (var index = 0; index < players.length; index++) 
    {
      var gamerStr = '<tr><td>' + players[index] + '</td></tr>';
      $('#next-round-table-body').append(gamerStr);
    }
}

function setLobbyScoreboard(players)
{
    // console.log('updatePlayboard: playboard = ', players);
    $('#results-table-body').html('');

    for (var index = 0; index < players.length; index++) 
    {
      // console.log('iterating through players: ' + index, players[index]);
      var gamerStr = '<tr><td>' + players[index].player_tag + '</td><td>' + players[index].points + '</td></tr>';
      $('#results-table-body').append(gamerStr);
    }
}

/*
  Games run on a fixed cadence of NUM_SECS_IN_COMPLETE_CYCLE.  
  Simple modulo math provides exactly where 'now' is within a cycle.  

  Each round consists of game time, plus lobby time between rounds.
  Lobby time is first, followed by game time (NUM_SECS_IN_LOBBY).  For this reason, 
  timeGameOver and timePrevGameOver will both always be perfect 
  multiples of NUM_MSECS_IN_COMPLETE_CYCLE.  
*/
function updateGameBounds()
{
  var now = new Date();
  var timePrevGameOver = Math.floor(now / NUM_MSECS_IN_COMPLETE_CYCLE)
                    * NUM_MSECS_IN_COMPLETE_CYCLE;  //  When previous round ended
  
  timeGameStarts = timePrevGameOver + NUM_MSECS_IN_COMPLETE_CYCLE;  //  When next round starts (and Lobby will end).
  $('#game-starts').html(formatTimeStr(timeGameStarts)); 
  
  timeGameOver = timeGameStarts - NUM_MSECS_IN_LOBBY;         //  When this round will end (and Lobby will start).
  $('#game-over').html(formatTimeStr(timeGameOver)); 
 
  if (now > timeGameOver)                       //  Has game already ended?
  {                                 //  ... YES, game has ended.
    timeGameOver += NUM_MSECS_IN_COMPLETE_CYCLE;          //    Update when next game ends
    $('#game-over').html(formatTimeStr(timeGameOver)); 
    setPage(LOBBY_PAGE);                      //    if we aren't already(!), go to Lobby page
  }
  else                                //  ... NO, game has not yet begun.
  {                                 
    setPage(PLAY_PAGE);                       //    if we aren't already(!), go to Play page
  }

  timeNextChange = Math.min(timeGameStarts, timeGameOver);
}

function formatTimeStr(eventTime)
{
  var date = new Date(eventTime);

  var hrs = date.getHours();
  if (hrs == 0)
  {
    hrs = 12;
  }
  if (hrs > 12) {
    hrs -= 12;
  }
  
  var nextRoundStr = hrs.toString();

  var minStr = ('0' + date.getMinutes()).slice(-2);
  nextRoundStr += ':' + ('0' + date.getMinutes()).slice(-2);
  return nextRoundStr;
}

function setPage(goToLobby)
{
  inLobby = goToLobby;
  if (goToLobby)
  {
    $('#play-page').css("display", "none");
    $('#lobby-page').css("display", "block");
  }
  else
  {
    $('#lobby-page').css("display", "none");
    askForFirstQuestion();
    
    $('#prog-bar-clr').toggleClass('progress-bar-primary', true);
    $('#prog-bar-clr').toggleClass('progress-bar-danger', false);
    
    $('#play-page').css("display", "block");
  }
}

function updateCountdownDisplay(secLeft, totalSecs)
{
  var secPart = secLeft % 60; 
  var minPart = Math.floor(secLeft / 60);
  var percentRemaining = secLeft * 100 / totalSecs;

  if (USE_AUDIO)
  {
    if ((secLeft <= NUM_SECS_AUDIO_WARNING) && !inLobby)
    {
      document.getElementById('tick').play();
    }
  }
  if (secLeft <= NUM_SECS_VISUAL_WARNING)
  {
    $('#prog-bar-clr').toggleClass('progress-bar-danger', true);
    $('#lobby-prog-bar-clr').toggleClass('progress-bar-danger', true);
    $('#prog-bar-clr').toggleClass('progress-bar-primary', false);
    $('#lobby-prog-bar-clr').toggleClass('progress-bar-primary', false);

    //  doesn't seem to work on IE
    $('#play-counter #game-over').toggleClass('urgent');
    $('#time-left').toggleClass('urgent');
  }

  if (inLobby)
  {
    $('#time-left').html('' + minPart + ":" + ("0" + secPart).slice(-2));
    return;
  }

  $('#prog-bar-bkgd').attr('style', "width:" + (100 - percentRemaining) + "%");
  $('#lobby-prog-bar-bkgd').attr('style', "width:" + (100 - percentRemaining) + "%");
  $('#prog-bar-clr').attr('style', "width:" + percentRemaining + "%");
  $('#lobby-prog-bar-clr').attr('style', "width:" + percentRemaining + "%");
  
  var barRemaining = "";
  if (percentRemaining >= 12) 
  {
    barRemaining += minPart + ":" + ("0" + secPart).slice(-2);
  }
  else if (percentRemaining >= 9)     // at < 12%, only display last 3 chars
  {
    barRemaining += ":" + ("0" + secPart).slice(-2);
  }
  // else if (percentRemaining >= 6.666)    // at < 9%, drop colon (only 2 chars)
  else if (secLeft >= 10)         // at < 9%, drop colon (only 2 chars)
  {
    barRemaining += ("0" + secPart).slice(-2);
  }
  // else if (percentRemaining >= 4)    // at < 6.666%, only display last 1 char
  else if (secLeft >= 7)          // at < 10 secs, only display last 1 char
  {
    barRemaining = (''+secPart).slice(-1);
  // }                    // at < 4%, display bar (no chars)  
  }                   // at < 7 secs, display bar (no chars)  
  $('#prog-bar-txt').html(barRemaining);
  $('#lobby-prog-bar-txt').html(barRemaining);
}

function setWarningText()
{
  retainWarningText = true;
  $('#score').toggleClass('urgent', true);      
}

function restoreWarningText()
{
  if (retainWarningText)
  {
    retainWarningText = false;
  }
  else
  {
    $('#score').toggleClass('urgent', false);     
  }
}

function playTick(tick_info)
{
  restoreWarningText();

  updateCountdownDisplay(tick_info.time_remaining, playDuration);
  updatePlayboard(tick_info.leaders)
}

function lobbyTick(secs_left)
{
  
  updateCountdownDisplay(secs_left, lobbyDuration);
}

function startTimer()
{
  updateGameBounds();
  globalTimer = setInterval(tick, TIMER_FREQUENCY_MSEC);      
}

function stopTimer()
{

  clearInterval(globalTimer);
}

function setAudioFileLocation()
{
  if (USE_AUDIO)
  {
    $('#audio-source').attr('src', AUDIO_WARNING_FILE);
    $('#alt-audio-source').attr('src', ALT_AUDIO_WARNING_FILE);
  }
}

function updateScore(outcome, points)
{
  if (outcome < 0)
  {
    setWarningText();
  }
  
  io.emit('player_scored', {points: points});
  console.log('EMIT: player_scored');

  $('#score span').html(points);
}

function updateCommentary(choice_id, prompt)
{
  //  this is where we would say something like 'The correct answer is Bb'(prompt)
  //  perhaps blink the button of the correct choice 

  console.log('updateCommentary()');
}

function updateQuestion(new_question, round_question_num)
{
  console.log(new_question);
  
  $('#prompt').html(new_question.prompt);
  $('#round-question-num').val(round_question_num);
  $('#diff-lvl').val(new_question.difficulty_level_id);
  $('#difficulty_level').html(new_question.difficulty_level_id);
  
  if (new_question.question_type_id == 0)
  {
    displayNote(new_question.content);
  }
  else
  {
    console.log("\n***************************************\n")
    console.log("*\tUnknown question type.\t*")
    console.log("\n***************************************\n")
  }
}

function updateChoices(new_choices)
{
  for (var i = 0; i < 5; i++)
  {
    $('#choice-btn-' + i).val(new_choices[i].id);
    $('#choice-btn-' + i).html(new_choices[i].prompt);
  }
}

function hideQuestionArea()
{
  console.log("hideQuestionArea()");
  $('#question-div').hide();
  $('#choices-div').hide();
}

function displayQuestion(question_info)
{
  console.log("displayQuestion()");

  if (!question_info['question'])
  {
    hideQuestionArea();
    return;
  }

  updateQuestion(question_info['question'], question_info['round_question_num']);
  updateChoices(question_info['choices']);
}

function nextQuestion(question_response)
{
  console.log("nextQuestion():" + question_response);
                                                     //  question_response contains both question_info and answer_info
  answer_info = question_response['answer_info']  
  updateScore(answer_info['outcome'], answer_info['points']);
  updateCommentary(answer_info['correct_id'], answer_info['correct_prompt']);

  displayQuestion(question_response);
}

function changeRoom(room_change_response)
{
  console.log("changeRoom():" + room_change_response);
  if (room_change_response['confirmed'] == true)
  {
    new_room = room_change_response['new_room'];
    new_profile = {difficulty_level: new_room};
    io.emit('change_room', {profile: new_profile} );    
    my_public_profile.diff_lvl = new_room;
  }
}

function startRound(length_of_round)
{
  $.post( '/round_started' );
  playDuration = length_of_round;
  setPage(PLAY_PAGE);
}

function endRound(length_of_lobby)
{
  lobbyDuration = length_of_lobby;
  setPage(LOBBY_PAGE);
  $.post( '/round_ended' );
  $('#score span').html(0);
}

function updateMyPoints(pts)
{

  my_public_profile.points = pts;
}

function updateMyDiffLvl(lvl)
{

  my_public_profile.difficulty_level = lvl;
}

function updateMyRoundStatus(round_is_incomplete)
{

  my_public_profile.incomplete_round = round_is_incomplete;
}

function askForFirstQuestion()
{
  console.log("askForFirstQuestion()");
  
  $.post( '/firstquestion',
          function(question_info)
            {
              console.log('about to call displayQuestion');
              console.info(question_info);
              displayQuestion(question_info);
            },
          "json"
        );
}

$(document).ready(function() 
  {
    console.log('entered document.ready()');

    initialConnect();
    scoreThisRound = 0;

    setAudioFileLocation();

  // ********************   JQuery functions  ********************
    $('#button-strip').on('submit', function()
      {
        console.log("#button-strip:submit", this);
        $.post( 
          $(this).attr('action'),
          $(this).serialize(), 
          function(question_response)
          {
            nextQuestion(question_response);
          },
          "json"
        );
        return false;
      });

    $(".quiz-btn").on('click', function()
      {
        $('#chosen-id').val($(this).val());
        $(this).parent().submit();
        return false;
      });

    $('#diff-lvl-strip').on('submit', function()
      {
        console.log("#diff-lvl-strip:submit", this);
        $.post( 
          $(this).attr('action'),
          $(this).serialize(), 
          function(room_change_response)
          {
            changeRoom(room_change_response);
          },
          "json"
        );
        return false;
      });

    $(".diff-lvl-btn").on('click', function()
      {
        $('.diff-lvl-btn').removeClass("btn-primary");
        $(this).addClass("btn-primary");

        $('#difficulty-level').val($(this).val());
        $(this).parent().submit();
        return false;
      });

  // ********************   Routing functions  ********************
    io.on('error_client_ready', function(errorMsg)
      {
        console.log('RECEIVED: error_client_ready');

        //  Actually, need to let the Rails server know, in this case.  
      });
    io.on('client_confirmed', function(clientRecord)
      {
        console.log('RECEIVED: client_confirmed');
        updateDifficultyLevel(clientRecord.diff_lvl);
        console.log('Tag:' + clientRecord.player_tag + ' Points:' + clientRecord.points + ' Diff lvl:' + clientRecord.diff_lvl + 'Incomplete round:' + clientRecord.incomplete_round);
      });
    io.on('gamers_already_in_room', function(players)
      {
        playersInRoom = [];
        console.log('RECEIVED: gamers_already_in_room');
        for (index in players.leaders)
        {
          var player = players.leaders[index];
          console.log(index, player.player_tag + ": " + player.points);
          playersInRoom.push(player.player_tag);
        }
        console.log(players);
        console.log(playersInRoom);
        updateLobbyboard(playersInRoom);
      });
    io.on('gamer_entered_room', function(public_player)
      {
        console.log('RECEIVED: gamer_entered_room: ' + public_player);
        console.log('Tag:' + public_player.player_tag + ' Points:' + public_player.points);
        playersInRoom.push(public_player.player_tag);
        updateLobbyboard(playersInRoom);
      });
    io.on('gamer_exited_room', function(player)
      {
        console.log('RECEIVED: gamer_exited_room ' + player.player_tag)
        console.info(player);
        var player_index = playersInRoom.indexOf(player.player_tag);
        if (player_index != -1)
        {
          playersInRoom.splice(player_index, 1);
          updateLobbyboard(playersInRoom);
        }
      });
    io.on('play_timer_update', function(tick_info)
      {
        console.log('RECEIVED: play_timer_update - ', tick_info);
        playTick(tick_info);
      });
    io.on('lobby_timer_update', function(secs_left)
      {
        console.log('RECEIVED: lobby_timer_update - ', secs_left);
        lobbyTick(secs_left);
      });
    io.on('round_started', function(length_of_round)
      {
        console.log('RECEIVED: round_started:' + length_of_round);
        startRound(length_of_round)
      });
    io.on('round_ended', function(length_of_lobby)
      {
        console.log('RECEIVED: round_ended:' + length_of_lobby);
        endRound(length_of_lobby);
        io.emit('request_final_score');
      });
    io.on('room_round_results', function(results)
      {
        console.log('RECEIVED: room_round_results');

        setLobbyScoreboard(results)
      });
    io.on('final_round_score', function(score)
      {
        console.log('RECEIVED: final_round_score ' + score.points + ' round_complete:' + score.round_complete);
      });
  });

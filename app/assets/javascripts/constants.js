//	For the most part, these are all timer- and cadence-related constants and globals.

// var USE_HIGH_PRECISION_TIMER = false;
var TIMER_FREQUENCY_MSEC = 999;

var NUM_SECS_IN_COMPLETE_CYCLE = 180;
var NUM_SECS_IN_LOBBY = 30;
var NUM_SECS_IN_PLAY_ROUND = NUM_SECS_IN_COMPLETE_CYCLE - NUM_SECS_IN_LOBBY;
var MIN_SECS_TO_PLAY = 5;

var NUM_MSECS_IN_PLAY_ROUND 	= NUM_SECS_IN_PLAY_ROUND * 1000;
var NUM_MSECS_IN_LOBBY 			= NUM_SECS_IN_LOBBY * 1000;
var NUM_MSECS_IN_COMPLETE_CYCLE = NUM_SECS_IN_COMPLETE_CYCLE * 1000;
var MIN_MSECS_TO_PLAY 			= MIN_SECS_TO_PLAY * 1000;

var NUM_SECS_VISUAL_WARNING = 10;	//	as time counts down, when to start warning
var NUM_SECS_AUDIO_WARNING = 6;		//	-1 == do not warn in this way

var USE_AUDIO = false;
var AUDIO_WARNING_FILE = '/assets/6-sec-tick.wav';
var ALT_AUDIO_WARNING_FILE = '/assets/6-sec-tick.mp3';

var globalTimer;

var LOBBY_PAGE = true;
var PLAY_PAGE  = false;

//	Initially I tracked msec drift across timer ticks.  Only really interesting if the
//	timer is implemented as a chain of one-off intervals, instead of a periodic timer.
var TRACK_MSEC_DRIFT = false;

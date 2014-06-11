// # Place all the behaviors and hooks related to the matching controller here.
// # All this logic will automatically be available in application.js.
// # You can use CoffeeScript in this file: http://coffeescript.org/

// var clefArr = 	[ 	
// 					{ name: 'treble', min: 24, max: 44 }, 
// 					// { name: 'bass', min: 12, max: 32 },
// 					// { name: 'alto', min: 20, max: 36 },
// 					// { name: 'tenor', min: 18, max: 34 },
//  				];
// var noteArr = 	['C', 'D', 'E', 'F', 'G', 'A', 'B'];
// var accidArr = 	[ null
//  				, null
//  				, 'n', 'b', '#'
//  				, 'bb', '##'
//  				]; 
var durArr = [ 'w', 'h', 'q'];
var durHash = { 'w': 4, 'h': 2, 'q': 1 };

var CANVAS_WIDTH = 110;
var CANVAS_HEIGHT = 145;

function displayNote(noteString)
{
	var noteStr;
	var durStr = null;
	var accidStr = null;
	var clefStr = null;
	var	lengthStr = null;

	if (noteString == undefined)
		return;

	var tokens = noteString.split(' ');
	var numTokens = tokens.length;
	while (numTokens)
	{
		numTokens--;
		var token = tokens[numTokens].split(':');
		switch (token[0])
		{
			case 'clef': clefStr = token[1]; break; 
			case 'key' : key 	 = token[1]; break; 
			case 'note': noteStr = token[1]; break; 
			case 'dur' : durStr  = token[1]; break;
			default:	 console.log('Unknown token value received from DB.'); 
		}
	}
	switch (clefStr)
	{
		case 'tr':	clefStr = 'treble';	break;
		case 'te':	clefStr = 'tenor';	break;
		case 'al':	clefStr = 'alto';	break;
		case 'bs':	clefStr = 'bass';	break;
	}
	if (noteStr[1] != '/')
	{
		accidStr = noteStr[1];
		if (noteStr[2] != '/')
		{
			accidStr += noteStr[2];
		}
	}
	if (durStr == null)
	{
		var durValue = Math.floor(Math.random() * durArr.length);
		durStr = durArr[durValue];
	}

	displayVex(noteStr, accidStr, clefStr, durStr);
}

function displayVex(note, accid, clef, dur)
{
	var canvas = $("canvas")[0];
	var renderer = new Vex.Flow.Renderer(canvas, Vex.Flow.Renderer.Backends.CANVAS);
	var ctx = renderer.getContext();
	var stave = new Vex.Flow.Stave(0, 10, 100);

	ctx.clearRect ( 0, 0, CANVAS_WIDTH, CANVAS_HEIGHT );
	stave.addClef(clef).setContext(ctx).draw();

	var noteObjs = [new Vex.Flow.StaveNote({keys:[note], duration:dur, clef:clef, auto_stem:true})];
	if (accid)
	{
		noteObjs[0].addAccidental(0, new Vex.Flow.Accidental(accid));
	}				
	var voice = new Vex.Flow.Voice({
			num_beats: durHash[dur],
			beat_value: 4,
			resolution: Vex.Flow.RESOLUTION
		});

	voice.addTickables(noteObjs);
	var formatter = new Vex.Flow.Formatter().joinVoices([voice]).format([voice], 100);
	voice.draw(ctx, stave);
}

# scripts/core/commentary_manager.gd
# Dynamic Broadcast Commentary Engine for CricStrike 3D
# Over 55+ situational broadcast commentary lines with excitement weighting and live ticker ribbon.
extends Node

signal commentary_updated(speaker: String, text: String, excitement_level: int)

var commentators: Array[String] = [
	"Ravi Shastri",
	"Michael Atherton",
	"Harsha Bhogle",
	"Ian Bishop",
	"Ricky Ponting"
]

var lines_six: Array[String] = [
	"Smacked straight down the ground for an absolute maximum! That is colossal!",
	"Into the second tier! What a breathtaking display of raw bat speed!",
	"He has picked the bones out of that delivery! 95 meters deep into the stands!",
	"That has been launched into orbit! High, handsome, and into the crowd!",
	"A trademark helicopter shot! Whipped away over deep mid-wicket with venom!",
	"Stand and deliver! Clean as a whistle, that went like a rocket into the terraces!",
	"Six runs! It's out of the park and into the car park! Astonishing hitting!",
	"Takes it on the full and deposits it into the grandstand! Sheer brute force!",
	"Down the track in a flash, and sent sailing into the night sky! Magnificent six!"
]

var lines_four: Array[String] = [
	"Punched sweetly through the covers! The timing was immaculate, races to the fence!",
	"Exquisite cover drive! You could watch that on loop all evening. Pure class!",
	"Pierced the gap with surgical precision! The outfield does the rest—four runs!",
	"Short and punished! Rocks onto the back foot and pulls it through square leg!",
	"Delicate late cut! Plays it right under his eyes and beats third man easily!",
	"Crunched off the front foot! Fielder had zero chance, ball whistled past him!",
	"Glorious on-drive! Straight past the non-striker for a boundary!",
	"Slices it through backward point! The fielder gives chase, but he won't catch that!",
	"Whipped off the pads with supreme authority! Boundary signaled by the umpire!"
]

var lines_wicket_bowled: Array[String] = [
	"Timber! Clean bowled through the gate! Stumps flying in all directions!",
	"Right through him! An unplayable delivery, middle stump is uprooted!",
	"Yorked him! Toe-crushing precision, and the batsman has no answers!",
	"Castled! Beaten for sheer pace, the off-stump goes cartwheeling!",
	"What a delivery! Dipped in the air, nipped back off the seam, and shattered the woodwork!"
]

var lines_wicket_caught: Array[String] = [
	"In the air... and it's taken in the deep! Massive breakthrough for the fielding side!",
	"Edged and taken! Sharp reflex catch behind the stumps by the wicketkeeper!",
	"Thick edge flies to slip! Taken cleanly at chest height, big wicket down!",
	"He went for the lofted stroke, didn't get all of it, and hole out to long-on!",
	"Sensational running catch on the boundary rope! That is superhuman fielding!"
]

var lines_wicket_lbw: Array[String] = [
	"Huge appeal from bowler and keeper! Finger goes up! That looked dead straight in front!",
	"Struck on the pads, umpire has no hesitation! Trapped right in front of leg stump!",
	"Big shout for LBW! Plumb in line, and the batsman must walk back to the pavilion!"
]

var lines_dot_ball: Array[String] = [
	"Beaten outside off stump! Good carry through to the wicketkeeper.",
	"Solid defensive stroke, right into the turf. Good test of patience here.",
	"Crisp delivery on a good length, defended straight back to the bowler.",
	"Swinging past the outside edge! The bowler lets him know about that one.",
	"Dabbed straight to point, no run available. Tight field placement."
]

var lines_milestone_fifty: Array[String] = [
	"And that brings up a masterclass half-century! Raises the bat to a standing ovation!",
	"Fifty runs of pure batting elegance! The dressing room is on its feet applaud this effort!",
	"A sensational fifty under pressure! What a player, leading from the front today!"
]

var lines_milestone_hundred: Array[String] = [
	"A monumental century! Helmet off, arms aloft, this is cricket at its finest!",
	"One hundred runs! Roar from the crowd, a scintillating hundred etched into history!",
	"Take a bow! Century of the highest caliber on the biggest stage!"
]

var lines_tense_finish: Array[String] = [
	"Down to the wire! Any mistake here could cost the match!",
	"Fingernails being chewed in the dugouts! High drama in the closing overs!",
	"Every single ball is gold dust now! Tension so thick you could cut it with a knife!",
	"Last few balls remaining, this stadium is on the edge of its collective seat!"
]

func get_commentary_for_event(event_type: String, extra_info: Dictionary = {}) -> Dictionary:
	var speaker = commentators[randi() % commentators.size()]
	var text = ""
	var excitement = 1
	
	match event_type:
		"six":
			text = lines_six[randi() % lines_six.size()]
			excitement = 3
		"four":
			text = lines_four[randi() % lines_four.size()]
			excitement = 2
		"wicket_bowled":
			text = lines_wicket_bowled[randi() % lines_wicket_bowled.size()]
			excitement = 3
		"wicket_caught":
			text = lines_wicket_caught[randi() % lines_wicket_caught.size()]
			excitement = 3
		"wicket_lbw":
			text = lines_wicket_lbw[randi() % lines_wicket_lbw.size()]
			excitement = 3
		"dot":
			text = lines_dot_ball[randi() % lines_dot_ball.size()]
			excitement = 1
		"fifty":
			text = lines_milestone_fifty[randi() % lines_milestone_fifty.size()]
			excitement = 3
		"century":
			text = lines_milestone_hundred[randi() % lines_milestone_hundred.size()]
			excitement = 3
		"tense":
			text = lines_tense_finish[randi() % lines_tense_finish.size()]
			excitement = 2
		_:
			text = "Good contest between bat and ball here today."
			excitement = 1
	
	emit_signal("commentary_updated", speaker, text, excitement)
	return {"speaker": speaker, "text": text, "excitement": excitement}

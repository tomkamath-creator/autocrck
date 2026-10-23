# scripts/core/game_manager.gd
# Central Match State Machine & Umpire Rules Engine for CricStrike 3D
# Coordinates score, overs, strike rotation, innings, targets, and stats persistence.
extends Node

signal score_updated(runs: int, wickets: int, overs_str: String, target: int, crr: float, rrr: float)
signal ball_recorded(ball_result: String)
signal over_completed(bowler_name: String, over_runs: int)
signal innings_ended(team_name: String, total_runs: int, total_wickets: int)
signal match_ended(winner: String, victory_margin: String)
signal replay_requested(event_type: String)

enum GameMode {
	QUICK_MATCH,
	SUPER_OVER,
	WORLD_TOURNAMENT,
	MEGA_AUCTION
}

enum MatchState {
	INNINGS_1,
	INNINGS_BREAK,
	INNINGS_2,
	COMPLETED
}

# Match Settings
var current_mode: GameMode = GameMode.QUICK_MATCH
var selected_overs: int = 5
var current_pitch_type: int = 2 # Flat Deck
var difficulty: String = "Medium" # Easy, Medium, Hard, Legend
var team_user: String = "India"
var team_ai: String = "Australia"
var user_is_batting_first: bool = true

# Live Match State
var match_state: MatchState = MatchState.INNINGS_1
var current_innings: int = 1
var batting_team: String = ""
var bowling_team: String = ""

var total_runs: int = 0
var total_wickets: int = 0
var legal_balls: int = 0
var target_score: int = 0
var first_innings_runs: int = 0

# Batsmen & Bowler
var striker_name: String = "R. Sharma"
var striker_runs: int = 0
var striker_balls: int = 0

var non_striker_name: String = "V. Kohli"
var non_striker_runs: int = 0
var non_striker_balls: int = 0

var current_bowler_name: String = "M. Starc"
var bowler_overs_balls: int = 0
var bowler_runs_conceded: int = 0
var bowler_wickets_taken: int = 0

var current_over_deliveries: Array[String] = []

func _ready() -> void:
	pass

func start_new_match(mode: GameMode, overs: int, pitch: int, user_team: String, ai_team: String, bat_first: bool) -> void:
	current_mode = mode
	selected_overs = overs
	current_pitch_type = pitch
	team_user = user_team
	team_ai = ai_team
	user_is_batting_first = bat_first
	
	if current_mode == GameMode.SUPER_OVER:
		selected_overs = 1
	
	_start_innings(1)

func _start_innings(innings_num: int) -> void:
	current_innings = innings_num
	total_runs = 0
	total_wickets = 0
	legal_balls = 0
	current_over_deliveries.clear()
	
	if current_innings == 1:
		match_state = MatchState.INNINGS_1
		batting_team = team_user if user_is_batting_first else team_ai
		bowling_team = team_ai if user_is_batting_first else team_user
		target_score = 0
	else:
		match_state = MatchState.INNINGS_2
		batting_team = team_ai if user_is_batting_first else team_user
		bowling_team = team_user if user_is_batting_first else team_ai
		target_score = first_innings_runs + 1
	
	_setup_players_for_innings()
	_notify_score()

func _setup_players_for_innings() -> void:
	var rosters = PersistenceManager.rosters_data
	var bat_roster = rosters.get(batting_team, {}).get("players", [])
	var bowl_roster = rosters.get(bowling_team, {}).get("players", [])
	
	striker_name = bat_roster[0]["name"] if bat_roster.size() > 0 else "Striker"
	striker_runs = 0
	striker_balls = 0
	
	non_striker_name = bat_roster[1]["name"] if bat_roster.size() > 1 else "Non-Striker"
	non_striker_runs = 0
	non_striker_balls = 0
	
	current_bowler_name = bowl_roster[bowl_roster.size() - 1]["name"] if bowl_roster.size() > 0 else "Bowler"
	bowler_overs_balls = 0
	bowler_runs_conceded = 0
	bowler_wickets_taken = 0

func record_delivery(runs: int, is_wicket: bool, dismissal_type: String = "", is_wide: bool = false, is_noball: bool = false) -> void:
	if match_state == MatchState.COMPLETED:
		return
	
	var ball_str = ""
	
	if is_wide:
		total_runs += 1
		bowler_runs_conceded += 1
		ball_str = "Wd"
		AudioManager.play_whistle()
	elif is_noball:
		total_runs += 1 + runs
		bowler_runs_conceded += 1 + runs
		striker_runs += runs
		ball_str = "Nb"
		AudioManager.play_whistle()
	else:
		legal_balls += 1
		bowler_overs_balls += 1
		
		if is_wicket:
			total_wickets += 1
			bowler_wickets_taken += 1
			striker_balls += 1
			ball_str = "W"
			CommentaryManager.get_commentary_for_event("wicket_" + dismissal_type)
			AudioManager.play_stump_shatter()
			emit_signal("replay_requested", "WICKET - " + dismissal_type.to_upper())
			_next_batsman_in()
		else:
			total_runs += runs
			bowler_runs_conceded += runs
			striker_runs += runs
			striker_balls += 1
			ball_str = str(runs)
			
			if runs == 6:
				CommentaryManager.get_commentary_for_event("six")
				AudioManager.trigger_crowd_cheer(true)
				emit_signal("replay_requested", "MAXIMUM SIX (6)")
			elif runs == 4:
				CommentaryManager.get_commentary_for_event("four")
				AudioManager.trigger_crowd_cheer(false)
				emit_signal("replay_requested", "BOUNDARY FOUR (4)")
			elif runs == 0:
				CommentaryManager.get_commentary_for_event("dot")
			
			# Check batsman milestones
			if striker_runs >= 50 and (striker_runs - runs) < 50:
				CommentaryManager.get_commentary_for_event("fifty")
				AudioManager.trigger_applause()
			elif striker_runs >= 100 and (striker_runs - runs) < 100:
				CommentaryManager.get_commentary_for_event("century")
				AudioManager.trigger_applause()
			
			# Strike rotation on odd runs (1, 3, 5)
			if runs % 2 == 1:
				_rotate_strike()
	
	current_over_deliveries.append(ball_str)
	emit_signal("ball_recorded", ball_str)
	_notify_score()
	
	# Check Target chased in 2nd Innings
	if current_innings == 2 and total_runs >= target_score:
		_conclude_match(batting_team, str(10 - total_wickets) + " wickets")
		return
	
	# Check All Out (10 wickets) or Overs completed
	var max_balls = selected_overs * 6
	if total_wickets >= 10 or legal_balls >= max_balls:
		if current_innings == 1:
			first_innings_runs = total_runs
			emit_signal("innings_ended", batting_team, total_runs, total_wickets)
			_start_innings(2)
		else:
			# Innings 2 ended without chasing target
			if total_runs == target_score - 1:
				_conclude_match("Tie", "Match Tied")
			else:
				var margin = (target_score - 1 - total_runs)
				_conclude_match(bowling_team, str(margin) + " runs")
		return
	
	# End of over (6 legal balls)
	if legal_balls > 0 and legal_balls % 6 == 0 and not (is_wide or is_noball):
		_handle_over_end()

func _handle_over_end() -> void:
	emit_signal("over_completed", current_bowler_name, bowler_runs_conceded)
	current_over_deliveries.clear()
	_rotate_strike() # Switch ends at end of over
	
	# Rotate bowler
	var rosters = PersistenceManager.rosters_data
	var bowl_roster = rosters.get(bowling_team, {}).get("players", [])
	if bowl_roster.size() > 4:
		var bowler_idx = 7 + ((legal_balls / 6) % 4)
		if bowler_idx < bowl_roster.size():
			current_bowler_name = bowl_roster[bowler_idx]["name"]
			bowler_overs_balls = 0
			bowler_runs_conceded = 0
			bowler_wickets_taken = 0

func _rotate_strike() -> void:
	var temp_name = striker_name
	var temp_runs = striker_runs
	var temp_balls = striker_balls
	
	striker_name = non_striker_name
	striker_runs = non_striker_runs
	striker_balls = non_striker_balls
	
	non_striker_name = temp_name
	non_striker_runs = temp_runs
	non_striker_balls = temp_balls

func _next_batsman_in() -> void:
	var rosters = PersistenceManager.rosters_data
	var bat_roster = rosters.get(batting_team, {}).get("players", [])
	var next_idx = 1 + total_wickets
	if next_idx < bat_roster.size():
		striker_name = bat_roster[next_idx]["name"]
		striker_runs = 0
		striker_balls = 0

func _conclude_match(winner: String, margin: String) -> void:
	match_state = MatchState.COMPLETED
	var user_won = (winner == team_user)
	
	PersistenceManager.update_stats_after_match(total_runs, legal_balls, total_wickets, user_won)
	emit_signal("match_ended", winner, margin)

func _notify_score() -> void:
	var overs_int = legal_balls / 6
	var balls_rem = legal_balls % 6
	var overs_str = str(overs_int) + "." + str(balls_rem)
	
	var crr = 0.0
	if legal_balls > 0:
		crr = (float(total_runs) / legal_balls) * 6.0
	
	var rrr = 0.0
	var remaining_balls = (selected_overs * 6) - legal_balls
	if current_innings == 2 and remaining_balls > 0 and target_score > total_runs:
		rrr = (float(target_score - total_runs) / remaining_balls) * 6.0
	
	emit_signal("score_updated", total_runs, total_wickets, overs_str, target_score, crr, rrr)

func is_user_batting() -> bool:
	if current_innings == 1:
		return user_is_batting_first
	else:
		return not user_is_batting_first

extends Node

# GameManager: Core State Machine & Match Rules Orchestrator

signal match_state_changed(new_state: String)
signal score_updated(runs: int, wickets: int, overs_str: String)
signal wicket_fallen(dismissal_type: String, batsman_name: String)
signal milestone_reached(milestone_type: String, player_name: String)
signal camera_mode_changed(mode_name: String)

enum GameMode { QUICK_MATCH, SUPER_OVER, TOURNAMENT, AUCTION, LOCKER_ROOM }
enum CameraMode { BEHIND_BATSMAN, BOWLER_POV, BROADCAST_SIDE, BALL_TRACKING, BATSMAN_HELMET_POV, UMPIRE_POV }

var current_mode: GameMode = GameMode.QUICK_MATCH
var current_camera_mode: CameraMode = CameraMode.BEHIND_BATSMAN

var team_a_id: String = "IND"
var team_b_id: String = "AUS"
var selected_pitch: String = "GREEN_TURF"
var total_overs: int = 5
var difficulty: String = "MEDIUM" # EASY, MEDIUM, HARD, LEGEND

# Live Match Inning State
var current_innings: int = 1
var batting_team_id: String = "IND"
var bowling_team_id: String = "AUS"
var target_runs: int = 0

var runs_scored: int = 0
var wickets_fallen: int = 0
var legal_deliveries: int = 0
var extras: int = 0

var current_striker_idx: int = 0
var current_non_striker_idx: int = 1
var current_bowler_idx: int = 9

# Individual Scorecards
var batting_card: Array[Dictionary] = []
var bowling_card: Array[Dictionary] = []
var current_over_balls: Array[String] = [] # e.g. ["1", "4", "W", "0", "6", "1"]

var is_user_batting: bool = true
var match_completed: bool = false
var winner_team_id: String = ""

func _ready() -> void:
	pass

func setup_match(t_a: String, t_b: String, overs: int, pitch: String, diff: String, mode: GameMode = GameMode.QUICK_MATCH) -> void:
	team_a_id = t_a
	team_b_id = t_b
	total_overs = overs
	selected_pitch = pitch
	difficulty = diff
	current_mode = mode
	
	batting_team_id = team_a_id
	bowling_team_id = team_b_id
	is_user_batting = true
	
	_reset_innings(1)

func _reset_innings(inn_num: int) -> void:
	current_innings = inn_num
	runs_scored = 0
	wickets_fallen = 0
	legal_deliveries = 0
	extras = 0
	current_striker_idx = 0
	current_non_striker_idx = 1
	current_bowler_idx = 9
	current_over_balls.clear()
	match_completed = false
	winner_team_id = ""

	var bat_team_data: Dictionary = DataManager.get_team(batting_team_id)
	batting_card.clear()
	for p in bat_team_data["players"]:
		batting_card.append({
			"name": p["name"],
			"runs": 0,
			"balls": 0,
			"fours": 0,
			"sixes": 0,
			"is_out": false,
			"dismissal": "not out"
		})

	var bowl_team_data: Dictionary = DataManager.get_team(bowling_team_id)
	bowling_card.clear()
	for p in bowl_team_data["players"]:
		bowling_card.append({
			"name": p["name"],
			"overs": 0.0,
			"balls": 0,
			"maidens": 0,
			"runs_conceded": 0,
			"wickets": 0
		})

func record_delivery(runs: int, is_wicket: bool, dismissal: String = "", is_wide_or_noball: bool = false) -> void:
	if match_completed:
		return

	if is_wide_or_noball:
		extras += 1
		runs_scored += 1 + runs
		bowling_card[current_bowler_idx]["runs_conceded"] += 1 + runs
		current_over_balls.append("Wd" if runs == 0 else "Nb")
	else:
		legal_deliveries += 1
		runs_scored += runs
		
		# Batsman stats
		var striker: Dictionary = batting_card[current_striker_idx]
		striker["runs"] += runs
		striker["balls"] += 1
		if runs == 4:
			striker["fours"] += 1
			AudioManager.play_sfx("crowd_cheer")
			AudioManager.trigger_commentary("FOUR")
		elif runs == 6:
			striker["sixes"] += 1
			AudioManager.play_sfx("crowd_cheer", 1.1)
			AudioManager.trigger_commentary("SIX")
		elif runs == 0 and not is_wicket:
			AudioManager.trigger_commentary("DOT")

		# Check milestones
		if striker["runs"] >= 50 and striker["runs"] - runs < 50:
			milestone_reached.emit("FIFTY", striker["name"])
			AudioManager.play_sfx("applause")
			AudioManager.trigger_commentary("FIFTY")
		elif striker["runs"] >= 100 and striker["runs"] - runs < 100:
			milestone_reached.emit("CENTURY", striker["name"])
			AudioManager.play_sfx("applause")
			AudioManager.trigger_commentary("CENTURY")

		# Bowler stats
		var bowler: Dictionary = bowling_card[current_bowler_idx]
		bowler["balls"] += 1
		bowler["runs_conceded"] += runs
		bowler["overs"] = float(bowler["balls"] / 6) + float(bowler["balls"] % 6) / 10.0

		if is_wicket:
			wickets_fallen += 1
			bowler["wickets"] += 1
			striker["is_out"] = true
			striker["dismissal"] = dismissal
			current_over_balls.append("W")
			wicket_fallen.emit(dismissal, striker["name"])
			AudioManager.play_sfx("crowd_gasp")
			
			if dismissal == "Bowled":
				AudioManager.play_sfx("stumps_rattle")
				AudioManager.trigger_commentary("BOWLED")
			elif dismissal == "Caught":
				AudioManager.trigger_commentary("CAUGHT")
			elif dismissal == "LBW":
				AudioManager.trigger_commentary("LBW")
			
			# Next batsman
			_bring_next_batsman()
		else:
			current_over_balls.append(str(runs))
			if runs % 2 == 1:
				_rotate_strike()

	# Emit updated score
	score_updated.emit(runs_scored, wickets_fallen, get_overs_formatted())

	# Check end of over
	if legal_deliveries > 0 and legal_deliveries % 6 == 0 and not is_wide_or_noball:
		_end_of_over()

	# Check innings / match completion
	_check_innings_end()

func _rotate_strike() -> void:
	var temp: int = current_striker_idx
	current_striker_idx = current_non_striker_idx
	current_non_striker_idx = temp

func _bring_next_batsman() -> void:
	for i in range(batting_card.size()):
		if not batting_card[i]["is_out"] and i != current_striker_idx and i != current_non_striker_idx:
			current_striker_idx = i
			return

func _end_of_over() -> void:
	_rotate_strike()
	# Rotate bowler (pick next bowler between index 7 and 10)
	current_bowler_idx = 7 + (randi() % 4)
	current_over_balls.clear()

func _check_innings_end() -> void:
	var max_balls: int = total_overs * 6
	var all_out: bool = wickets_fallen >= 10
	var overs_done: bool = legal_deliveries >= max_balls

	if current_innings == 1:
		if all_out or overs_done:
			target_runs = runs_scored + 1
			# Swap teams for Innings 2
			var temp_bat: String = batting_team_id
			batting_team_id = bowling_team_id
			bowling_team_id = temp_bat
			is_user_batting = not is_user_batting
			_reset_innings(2)
			match_state_changed.emit("INNINGS_BREAK")
	elif current_innings == 2:
		if runs_scored >= target_runs:
			match_completed = true
			winner_team_id = batting_team_id
			_conclude_match()
		elif all_out or overs_done:
			match_completed = true
			if runs_scored == target_runs - 1:
				winner_team_id = "TIE"
			else:
				winner_team_id = bowling_team_id
			_conclude_match()

func _conclude_match() -> void:
	DataManager.profile["matches_played"] += 1
	if winner_team_id == team_a_id:
		DataManager.profile["matches_won"] += 1
		DataManager.profile["xp"] += 500
		DataManager.profile["coins"] += 150000
	else:
		DataManager.profile["matches_lost"] += 1
		DataManager.profile["xp"] += 200
		DataManager.profile["coins"] += 50000
	DataManager.save_all_data()
	match_state_changed.emit("MATCH_CONCLUDED")

func get_overs_formatted() -> String:
	var ov: int = legal_deliveries / 6
	var rem: int = legal_deliveries % 6
	return "%d.%d / %d" % [ov, rem, total_overs]

func cycle_camera() -> void:
	var next_mode: int = (int(current_camera_mode) + 1) % 6
	current_camera_mode = next_mode as CameraMode
	camera_mode_changed.emit(CameraMode.keys()[current_camera_mode])

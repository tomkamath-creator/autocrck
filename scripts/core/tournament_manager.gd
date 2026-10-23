# scripts/core/tournament_manager.gd
# World Tournament Engine for CricStrike 3D
# 8-Team Group Stage, Points Table, Net Run Rate (NRR), Knockout Bracket & Trophy Presentation.
extends Node

signal tournament_state_changed()

var tournament_teams: Array[String] = [
	"India", "Australia", "England", "South Africa",
	"Pakistan", "New Zealand", "West Indies", "Sri Lanka"
]

var user_selected_team: String = "India"
var current_stage: String = "GROUP_STAGE" # GROUP_STAGE, SEMI_FINALS, FINAL, TROPHY
var current_match_index: int = 0

# Points Table: Team -> {P, W, L, PTS, RunsScored, OversFaced, RunsConceded, OversBowled, NRR}
var points_table_a: Dictionary = {}
var points_table_b: Dictionary = {}

var group_a_teams: Array[String] = []
var group_b_teams: Array[String] = []

var fixtures_group: Array[Dictionary] = []
var semi_final_1: Dictionary = {}
var semi_final_2: Dictionary = {}
var grand_final: Dictionary = {}
var tournament_winner: String = ""

func _ready() -> void:
	if PersistenceManager.has_saved_tournament():
		load_tournament_state()

func initialize_new_tournament(user_team: String) -> void:
	user_selected_team = user_team
	current_stage = "GROUP_STAGE"
	current_match_index = 0
	tournament_winner = ""
	
	# Split into Group A and Group B
	var shuffled = tournament_teams.duplicate()
	shuffled.shuffle()
	# Ensure user team is in Group A
	shuffled.erase(user_team)
	group_a_teams = [user_team, shuffled[0], shuffled[1], shuffled[2]]
	group_b_teams = [shuffled[3], shuffled[4], shuffled[5], shuffled[6]]
	
	_init_table(group_a_teams, points_table_a)
	_init_table(group_b_teams, points_table_b)
	
	_generate_group_fixtures()
	save_tournament_state()
	emit_signal("tournament_state_changed")

func _init_table(teams: Array[String], table: Dictionary) -> void:
	table.clear()
	for t in teams:
		table[t] = {
			"team": t,
			"P": 0, "W": 0, "L": 0, "PTS": 0,
			"runs_scored": 0, "balls_faced": 0,
			"runs_conceded": 0, "balls_bowled": 0,
			"NRR": 0.0
		}

func _generate_group_fixtures() -> void:
	fixtures_group.clear()
	# Group A Round Robin
	for i in range(group_a_teams.size()):
		for j in range(i + 1, group_a_teams.size()):
			fixtures_group.append({
				"group": "A",
				"team1": group_a_teams[i],
				"team2": group_a_teams[j],
				"played": false,
				"winner": "",
				"score1": "", "score2": ""
			})
	# Group B Round Robin
	for i in range(group_b_teams.size()):
		for j in range(i + 1, group_b_teams.size()):
			fixtures_group.append({
				"group": "B",
				"team1": group_b_teams[i],
				"team2": group_b_teams[j],
				"played": false,
				"winner": "",
				"score1": "", "score2": ""
			})

func get_next_fixture() -> Dictionary:
	for f in fixtures_group:
		if not f["played"]:
			return f
	if current_stage == "SEMI_FINALS":
		if not semi_final_1["played"]:
			return semi_final_1
		if not semi_final_2["played"]:
			return semi_final_2
	elif current_stage == "FINAL":
		if not grand_final["played"]:
			return grand_final
	return {}

func record_fixture_result(fixture: Dictionary, winner: String, runs1: int, balls1: int, runs2: int, balls2: int) -> void:
	fixture["played"] = true
	fixture["winner"] = winner
	fixture["score1"] = str(runs1)
	fixture["score2"] = str(runs2)
	
	if current_stage == "GROUP_STAGE":
		var t1 = fixture["team1"]
		var t2 = fixture["team2"]
		var table = points_table_a if fixture["group"] == "A" else points_table_b
		
		_update_team_stats(table[t1], runs1, balls1, runs2, balls2, winner == t1)
		_update_team_stats(table[t2], runs2, balls2, runs1, balls1, winner == t2)
		
		# Check if all group fixtures completed
		var all_done = true
		for f in fixtures_group:
			if not f["played"]:
				all_done = false
				break
		if all_done:
			_transition_to_semi_finals()
			
	elif current_stage == "SEMI_FINALS":
		if semi_final_1["played"] and semi_final_2["played"]:
			_transition_to_final()
			
	elif current_stage == "FINAL":
		current_stage = "TROPHY"
		tournament_winner = winner
		PersistenceManager.profile_data["trophies"] += 1
		PersistenceManager.save_profile()
	
	save_tournament_state()
	emit_signal("tournament_state_changed")

func _update_team_stats(entry: Dictionary, runs_for: int, balls_for: int, runs_against: int, balls_against: int, won: bool) -> void:
	entry["P"] += 1
	if won:
		entry["W"] += 1
		entry["PTS"] += 2
	else:
		entry["L"] += 1
	
	entry["runs_scored"] += runs_for
	entry["balls_faced"] += balls_for
	entry["runs_conceded"] += runs_against
	entry["balls_bowled"] += balls_against
	
	# Net Run Rate = (Runs / Overs Faced) - (Runs / Overs Bowled)
	var overs_for = float(entry["balls_faced"]) / 6.0
	var overs_against = float(entry["balls_bowled"]) / 6.0
	var for_rate = (entry["runs_scored"] / overs_for) if overs_for > 0.1 else 0.0
	var against_rate = (entry["runs_conceded"] / overs_against) if overs_against > 0.1 else 0.0
	entry["NRR"] = snapped(for_rate - against_rate, 0.001)

func _transition_to_semi_finals() -> void:
	current_stage = "SEMI_FINALS"
	var sorted_a = get_sorted_table(points_table_a)
	var sorted_b = get_sorted_table(points_table_b)
	
	# SF1: 1st Group A vs 2nd Group B
	semi_final_1 = {
		"stage": "Semi-Final 1",
		"team1": sorted_a[0]["team"],
		"team2": sorted_b[1]["team"],
		"played": false,
		"winner": ""
	}
	# SF2: 1st Group B vs 2nd Group A
	semi_final_2 = {
		"stage": "Semi-Final 2",
		"team1": sorted_b[0]["team"],
		"team2": sorted_a[1]["team"],
		"played": false,
		"winner": ""
	}

func _transition_to_final() -> void:
	current_stage = "FINAL"
	grand_final = {
		"stage": "Grand Final",
		"team1": semi_final_1["winner"],
		"team2": semi_final_2["winner"],
		"played": false,
		"winner": ""
	}

func get_sorted_table(table: Dictionary) -> Array:
	var list = table.values()
	list.sort_custom(func(a, b):
		if a["PTS"] != b["PTS"]:
			return a["PTS"] > b["PTS"]
		return a["NRR"] > b["NRR"]
	)
	return list

func simulate_ai_match(fixture: Dictionary) -> void:
	var r1 = randi_range(65, 110)
	var r2 = randi_range(60, 105)
	if r1 == r2: r1 += 1
	var winner = fixture["team1"] if r1 > r2 else fixture["team2"]
	record_fixture_result(fixture, winner, r1, 30, r2, 30)

func save_tournament_state() -> void:
	var state = {
		"user_team": user_selected_team,
		"stage": current_stage,
		"group_a": group_a_teams,
		"group_b": group_b_teams,
		"table_a": points_table_a,
		"table_b": points_table_b,
		"fixtures": fixtures_group,
		"sf1": semi_final_1,
		"sf2": semi_final_2,
		"final": grand_final,
		"winner": tournament_winner
	}
	PersistenceManager.save_tournament(state)

func load_tournament_state() -> void:
	var state = PersistenceManager.load_tournament()
	if state.is_empty():
		return
	user_selected_team = state.get("user_team", "India")
	current_stage = state.get("stage", "GROUP_STAGE")
	group_a_teams = state.get("group_a", [])
	group_b_teams = state.get("group_b", [])
	points_table_a = state.get("table_a", {})
	points_table_b = state.get("table_b", {})
	fixtures_group = state.get("fixtures", [])
	semi_final_1 = state.get("sf1", {})
	semi_final_2 = state.get("sf2", {})
	grand_final = state.get("final", {})
	tournament_winner = state.get("winner", "")

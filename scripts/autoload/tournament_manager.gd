extends Node

# TournamentManager: Group Stages, Points Table, Net Run Rate (NRR) & Knockout Brackets

signal tournament_updated()

var current_stage: String = "GROUP_STAGE" # GROUP_STAGE, SEMI_FINALS, FINAL, COMPLETED
var user_team_id: String = "IND"
var group_a_teams: Array[String] = ["IND", "AUS", "PAK", "NZ"]
var group_b_teams: Array[String] = ["ENG", "SA", "WI", "SL"]

var points_table: Dictionary = {}
var fixtures: Array[Dictionary] = []
var current_fixture_idx: int = 0
var semi_finalists: Array[String] = []
var finalists: Array[String] = []
var champion_team: String = ""

func _ready() -> void:
	pass

func init_tournament(selected_team: String) -> void:
	user_team_id = selected_team
	current_stage = "GROUP_STAGE"
	current_fixture_idx = 0
	semi_finalists.clear()
	finalists.clear()
	champion_team = ""
	
	points_table.clear()
	var all_teams: Array[String] = group_a_teams + group_b_teams
	for t in all_teams:
		points_table[t] = {
			"team_id": t,
			"name": DataManager.get_team(t)["name"],
			"played": 0,
			"won": 0,
			"lost": 0,
			"points": 0,
			"runs_scored": 0,
			"overs_faced": 0.0,
			"runs_conceded": 0,
			"overs_bowled": 0.0,
			"nrr": 0.0
		}
	
	_generate_group_fixtures()
	tournament_updated.emit()

func _generate_group_fixtures() -> void:
	fixtures.clear()
	# Group A round robin
	for i in range(group_a_teams.size()):
		for j in range(i + 1, group_a_teams.size()):
			fixtures.append({
				"stage": "Group A",
				"team_1": group_a_teams[i],
				"team_2": group_a_teams[j],
				"completed": false,
				"winner": ""
			})
	# Group B round robin
	for i in range(group_b_teams.size()):
		for j in range(i + 1, group_b_teams.size()):
			fixtures.append({
				"stage": "Group B",
				"team_1": group_b_teams[i],
				"team_2": group_b_teams[j],
				"completed": false,
				"winner": ""
			})

func simulate_next_fixture_or_play() -> Dictionary:
	if current_fixture_idx >= fixtures.size():
		return {}
	return fixtures[current_fixture_idx]

func record_fixture_result(winner_id: String, runs_a: int, overs_a: float, runs_b: int, overs_b: float) -> void:
	if current_fixture_idx >= fixtures.size():
		return
	var fix: Dictionary = fixtures[current_fixture_idx]
	fix["completed"] = true
	fix["winner"] = winner_id
	
	var t1: String = fix["team_1"]
	var t2: String = fix["team_2"]
	
	if points_table.has(t1) and points_table.has(t2):
		var p1: Dictionary = points_table[t1]
		var p2: Dictionary = points_table[t2]
		
		p1["played"] += 1
		p2["played"] += 1
		
		if winner_id == t1:
			p1["won"] += 1
			p1["points"] += 2
			p2["lost"] += 1
		elif winner_id == t2:
			p2["won"] += 1
			p2["points"] += 2
			p1["lost"] += 1
			
		p1["runs_scored"] += runs_a
		p1["overs_faced"] += overs_a
		p1["runs_conceded"] += runs_b
		p1["overs_bowled"] += overs_b
		
		p2["runs_scored"] += runs_b
		p2["overs_faced"] += overs_b
		p2["runs_conceded"] += runs_a
		p2["overs_bowled"] += overs_a
		
		_calc_nrr(p1)
		_calc_nrr(p2)
	
	current_fixture_idx += 1
	_check_stage_progression()
	tournament_updated.emit()

func _calc_nrr(p: Dictionary) -> void:
	var bat_rate: float = (float(p["runs_scored"]) / max(p["overs_faced"], 1.0))
	var bowl_rate: float = (float(p["runs_conceded"]) / max(p["overs_bowled"], 1.0))
	p["nrr"] = snappedf(bat_rate - bowl_rate, 0.001)

func _check_stage_progression() -> void:
	if current_stage == "GROUP_STAGE" and current_fixture_idx >= fixtures.size():
		# Determine top 2 of Group A and Group B
		var sorted_a: Array = group_a_teams.duplicate()
		sorted_a.sort_custom(func(a, b):
			if points_table[a]["points"] == points_table[b]["points"]:
				return points_table[a]["nrr"] > points_table[b]["nrr"]
			return points_table[a]["points"] > points_table[b]["points"]
		)
		var sorted_b: Array = group_b_teams.duplicate()
		sorted_b.sort_custom(func(a, b):
			if points_table[a]["points"] == points_table[b]["points"]:
				return points_table[a]["nrr"] > points_table[b]["nrr"]
			return points_table[a]["points"] > points_table[b]["points"]
		)
		
		semi_finalists = [sorted_a[0], sorted_b[1], sorted_b[0], sorted_a[1]]
		current_stage = "SEMI_FINALS"
		fixtures.clear()
		current_fixture_idx = 0
		fixtures.append({"stage": "Semi-Final 1", "team_1": semi_finalists[0], "team_2": semi_finalists[1], "completed": false, "winner": ""})
		fixtures.append({"stage": "Semi-Final 2", "team_1": semi_finalists[2], "team_2": semi_finalists[3], "completed": false, "winner": ""})
	elif current_stage == "SEMI_FINALS" and current_fixture_idx >= fixtures.size():
		finalists = [fixtures[0]["winner"], fixtures[1]["winner"]]
		current_stage = "FINAL"
		fixtures.clear()
		current_fixture_idx = 0
		fixtures.append({"stage": "Grand Final", "team_1": finalists[0], "team_2": finalists[1], "completed": false, "winner": ""})
	elif current_stage == "FINAL" and current_fixture_idx >= fixtures.size():
		champion_team = fixtures[0]["winner"]
		current_stage = "COMPLETED"
		if champion_team == user_team_id:
			DataManager.profile["tournaments_won"] += 1
			DataManager.profile["coins"] += 1000000
			DataManager.save_all_data()

func simulate_ai_fixture(fix: Dictionary) -> void:
	var t1: String = fix["team_1"]
	var t2: String = fix["team_2"]
	var winner: String = t1 if randf() > 0.48 else t2
	var r1: int = randi_range(140, 210)
	var r2: int = randi_range(130, 205)
	if winner == t1 and r2 >= r1:
		r1 = r2 + randi_range(1, 15)
	elif winner == t2 and r1 >= r2:
		r2 = r1 + randi_range(1, 15)
	record_fixture_result(winner, r1, 20.0, r2, 20.0)

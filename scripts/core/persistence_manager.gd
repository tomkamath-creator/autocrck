# scripts/core/persistence_manager.gd
# 100% Offline Structured JSON Persistence Manager for CricStrike 3D
# Manages local saves in user:// without any external network dependencies.
extends Node

const SAVE_DIR := "user://"
const PROFILE_FILE := SAVE_DIR + "player_profile.json"
const CUSTOM_PLAYER_FILE := SAVE_DIR + "custom_player.json"
const TOURNAMENT_SAVE_FILE := SAVE_DIR + "tournament_save.json"
const AUCTION_SAVE_FILE := SAVE_DIR + "auction_save.json"
const SETTINGS_FILE := SAVE_DIR + "settings.json"
const ROSTER_FILE := SAVE_DIR + "team_rosters.json"

var profile_data: Dictionary = {}
var custom_player_data: Dictionary = {}
var settings_data: Dictionary = {}
var rosters_data: Dictionary = {}

func _ready() -> void:
	load_all_data()

func load_all_data() -> void:
	profile_data = _load_json(PROFILE_FILE, _get_default_profile())
	custom_player_data = _load_json(CUSTOM_PLAYER_FILE, _get_default_custom_player())
	settings_data = _load_json(SETTINGS_FILE, _get_default_settings())
	rosters_data = _load_json(ROSTER_FILE, _get_default_rosters())

func save_profile() -> void:
	_save_json(PROFILE_FILE, profile_data)

func save_custom_player() -> void:
	_save_json(CUSTOM_PLAYER_FILE, custom_player_data)

func save_settings() -> void:
	_save_json(SETTINGS_FILE, settings_data)

func save_rosters() -> void:
	_save_json(ROSTER_FILE, rosters_data)

func save_tournament(data: Dictionary) -> void:
	_save_json(TOURNAMENT_SAVE_FILE, data)

func load_tournament() -> Dictionary:
	return _load_json(TOURNAMENT_SAVE_FILE, {})

func has_saved_tournament() -> bool:
	return FileAccess.file_exists(TOURNAMENT_SAVE_FILE)

func clear_saved_tournament() -> void:
	if FileAccess.file_exists(TOURNAMENT_SAVE_FILE):
		DirAccess.remove_absolute(TOURNAMENT_SAVE_FILE)

func save_auction(data: Dictionary) -> void:
	_save_json(AUCTION_SAVE_FILE, data)

func load_auction() -> Dictionary:
	return _load_json(AUCTION_SAVE_FILE, {})

func update_stats_after_match(runs_scored: int, balls_faced: int, wickets_taken: int, won: bool) -> void:
	profile_data["matches_played"] += 1
	if won:
		profile_data["matches_won"] += 1
	profile_data["total_runs"] += runs_scored
	profile_data["total_wickets"] += wickets_taken
	if runs_scored > profile_data["high_score"]:
		profile_data["high_score"] = runs_scored
	# XP and coins rewards
	var earned_coins = (runs_scored * 10) + (wickets_taken * 50) + (500 if won else 150)
	profile_data["coins"] += earned_coins
	profile_data["xp"] += (runs_scored * 5) + (wickets_taken * 25) + 100
	profile_data["level"] = 1 + int(profile_data["xp"] / 1000)
	save_profile()

func _save_json(path: String, data: Dictionary) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(data, "\t")
		file.store_string(json_string)
		file.close()

func _load_json(path: String, fallback: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		_save_json(path, fallback)
		return fallback
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return fallback
	var content = file.get_as_text()
	file.close()
	var test_json_conv = JSON.new()
	var parse_err = test_json_conv.parse(content)
	if parse_err == OK and typeof(test_json_conv.data) == TYPE_DICTIONARY:
		return test_json_conv.data
	return fallback

func _get_default_profile() -> Dictionary:
	return {
		"player_name": "Champion",
		"level": 1,
		"xp": 0,
		"coins": 5000,
		"matches_played": 0,
		"matches_won": 0,
		"total_runs": 0,
		"total_wickets": 0,
		"high_score": 0,
		"trophies": 0
	}

func _get_default_custom_player() -> Dictionary:
	return {
		"name": "V. STRIKER",
		"jersey_number": 18,
		"role": "Batsman", # Batsman, Bowler, All-Rounder, Wicketkeeper
		"batting_hand": "Right", # Right, Left
		"bowling_style": "Fast", # Fast, Fast-Medium, Off-Spin, Leg-Spin
		"build_type": "Athletic", # Athletic, Slim, Heavy
		"skin_tone": 1, # 0: Fair, 1: Wheatish/Subcontinental, 2: Dark
		"hair_style": 0,
		"facial_hair": 1,
		"bat_willow": "Grade 1 English Willow",
		"bat_sticker": "STRIKE_PRO",
		"jersey_primary": "#0a3871",
		"jersey_secondary": "#ff9900",
		"pad_color": "#ffffff",
		"helmet_color": "#0a3871"
	}

func _get_default_settings() -> Dictionary:
	return {
		"master_volume": 1.0,
		"sfx_volume": 0.9,
		"commentary_volume": 0.95,
		"crowd_volume": 0.85,
		"camera_mode": "BEHIND_BATSMAN",
		"graphics_quality": "High",
		"target_fps": 60,
		"pitch_markers_visible": true,
		"wagon_wheel_enabled": true,
		"ultraedge_enabled": true
	}

func _get_default_rosters() -> Dictionary:
	return {
		"India": {
			"color_primary": "#0b3b75",
			"color_secondary": "#ff8c00",
			"players": [
				{"name": "R. Sharma", "role": "Batsman", "bat": 92, "bowl": 35, "num": 45},
				{"name": "S. Gill", "role": "Batsman", "bat": 88, "bowl": 30, "num": 77},
				{"name": "V. Kohli", "role": "Batsman", "bat": 96, "bowl": 40, "num": 18},
				{"name": "S. Yadav", "role": "Batsman", "bat": 90, "bowl": 30, "num": 63},
				{"name": "H. Pandya", "role": "All-Rounder", "bat": 86, "bowl": 84, "num": 33},
				{"name": "R. Pant", "role": "Wicketkeeper", "bat": 87, "bowl": 20, "num": 17},
				{"name": "R. Jadeja", "role": "All-Rounder", "bat": 84, "bowl": 89, "num": 8},
				{"name": "A. Patel", "role": "All-Rounder", "bat": 80, "bowl": 86, "num": 20},
				{"name": "K. Yadav", "role": "Bowler", "bat": 50, "bowl": 91, "num": 23},
				{"name": "J. Bumrah", "role": "Bowler", "bat": 45, "bowl": 98, "num": 93},
				{"name": "M. Siraj", "role": "Bowler", "bat": 40, "bowl": 89, "num": 13}
			]
		},
		"Australia": {
			"color_primary": "#e6b800",
			"color_secondary": "#004d20",
			"players": [
				{"name": "T. Head", "role": "Batsman", "bat": 91, "bowl": 45, "num": 62},
				{"name": "D. Warner", "role": "Batsman", "bat": 89, "bowl": 30, "num": 31},
				{"name": "M. Marsh", "role": "All-Rounder", "bat": 87, "bowl": 80, "num": 8},
				{"name": "S. Smith", "role": "Batsman", "bat": 93, "bowl": 40, "num": 49},
				{"name": "G. Maxwell", "role": "All-Rounder", "bat": 89, "bowl": 78, "num": 32},
				{"name": "M. Stoinis", "role": "All-Rounder", "bat": 83, "bowl": 81, "num": 17},
				{"name": "J. Inglis", "role": "Wicketkeeper", "bat": 84, "bowl": 20, "num": 48},
				{"name": "P. Cummins", "role": "Bowler", "bat": 75, "bowl": 95, "num": 30},
				{"name": "M. Starc", "role": "Bowler", "bat": 65, "bowl": 94, "num": 56},
				{"name": "A. Zampa", "role": "Bowler", "bat": 45, "bowl": 90, "num": 88},
				{"name": "J. Hazlewood", "role": "Bowler", "bat": 40, "bowl": 93, "num": 38}
			]
		},
		"England": {
			"color_primary": "#0a2240",
			"color_secondary": "#cc0000",
			"players": [
				{"name": "J. Buttler", "role": "Wicketkeeper", "bat": 92, "bowl": 20, "num": 63},
				{"name": "P. Salt", "role": "Batsman", "bat": 87, "bowl": 25, "num": 28},
				{"name": "W. Jacks", "role": "All-Rounder", "bat": 84, "bowl": 75, "num": 85},
				{"name": "H. Brook", "role": "Batsman", "bat": 88, "bowl": 30, "num": 88},
				{"name": "J. Bairstow", "role": "Batsman", "bat": 86, "bowl": 20, "num": 51},
				{"name": "L. Livingstone", "role": "All-Rounder", "bat": 85, "bowl": 79, "num": 23},
				{"name": "S. Curran", "role": "All-Rounder", "bat": 81, "bowl": 86, "num": 58},
				{"name": "C. Jordan", "role": "Bowler", "bat": 60, "bowl": 83, "num": 34},
				{"name": "J. Archer", "role": "Bowler", "bat": 60, "bowl": 94, "num": 22},
				{"name": "A. Rashid", "role": "Bowler", "bat": 50, "bowl": 91, "num": 95},
				{"name": "M. Wood", "role": "Bowler", "bat": 45, "bowl": 92, "num": 33}
			]
		},
		"South Africa": {
			"color_primary": "#005a36",
			"color_secondary": "#ffcc00",
			"players": [
				{"name": "Q. de Kock", "role": "Wicketkeeper", "bat": 91, "bowl": 20, "num": 12},
				{"name": "R. Hendricks", "role": "Batsman", "bat": 84, "bowl": 25, "num": 17},
				{"name": "A. Markram", "role": "Batsman", "bat": 88, "bowl": 74, "num": 94},
				{"name": "H. Klaasen", "role": "Batsman", "bat": 93, "bowl": 20, "num": 45},
				{"name": "D. Miller", "role": "Batsman", "bat": 89, "bowl": 20, "num": 10},
				{"name": "T. Stubbs", "role": "Batsman", "bat": 85, "bowl": 30, "num": 30},
				{"name": "M. Jansen", "role": "All-Rounder", "bat": 79, "bowl": 88, "num": 70},
				{"name": "K. Maharaj", "role": "Bowler", "bat": 60, "bowl": 89, "num": 16},
				{"name": "K. Rabada", "role": "Bowler", "bat": 55, "bowl": 96, "num": 25},
				{"name": "A. Nortje", "role": "Bowler", "bat": 45, "bowl": 93, "num": 20},
				{"name": "T. Shamsi", "role": "Bowler", "bat": 35, "bowl": 88, "num": 26}
			]
		}
	}

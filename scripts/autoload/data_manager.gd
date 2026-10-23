extends Node

# DataManager: 100% Offline Persistence and Master Rosters for CricStrike 3D

const SAVE_PATH: String = "user://cricstrike_save.json"
const CUSTOM_PLAYER_PATH: String = "user://custom_players.json"

var profile: Dictionary = {
	"player_name": "Pro Cricketer",
	"level": 1,
	"xp": 0,
	"coins": 25000000, # Initial purse for mega auction
	"matches_played": 0,
	"matches_won": 0,
	"matches_lost": 0,
	"total_runs": 0,
	"total_wickets": 0,
	"highest_score": 0,
	"most_sixes": 0,
	"tournaments_won": 0
}

var custom_player: Dictionary = {
	"name": "MY CRICKETER",
	"number": 7,
	"role": "ALL_ROUNDER",
	"batting_style": "RIGHT_HAND",
	"bowling_style": "RIGHT_ARM_FAST",
	"skin_tone": 2, # 0 to 4
	"facial_hair": 1, # 0 to 3
	"build_type": "ATHLETIC", # ATHLETIC, SLIM, HEAVY
	"bat_willow": "ENGLISH_GRADE_1",
	"bat_sticker": "CS_BLASTER",
	"jersey_color": "#0d3b66",
	"jersey_accent": "#f4d35e"
}

var teams: Dictionary = {}
var franchises: Dictionary = {}
var pitch_types: Dictionary = {
	"GREEN_TURF": {
		"name": "Green Turf",
		"description": "Lively grass deck offering steep bounce and generous seam movement.",
		"restitution": 0.84,
		"friction": 0.32,
		"seam_factor": 0.08,
		"spin_factor": 0.04,
		"color": Color(0.28, 0.52, 0.22)
	},
	"DUSTY_PITCH": {
		"name": "Dusty Pitch",
		"description": "Dry crumbling surface with intense spin grip and abrasive variable bounce.",
		"restitution": 0.65,
		"friction": 0.48,
		"seam_factor": 0.02,
		"spin_factor": 0.12,
		"color": Color(0.72, 0.61, 0.44)
	},
	"FLAT_DECK": {
		"name": "Flat Deck",
		"description": "True bounce batting paradise with minimal lateral seam movement.",
		"restitution": 0.78,
		"friction": 0.30,
		"seam_factor": 0.03,
		"spin_factor": 0.05,
		"color": Color(0.68, 0.58, 0.40)
	},
	"WET_PITCH": {
		"name": "Wet Pitch",
		"description": "Damp pitch with skidding low trajectory and unpredictable pace off turf.",
		"restitution": 0.58,
		"friction": 0.52,
		"seam_factor": 0.05,
		"spin_factor": 0.03,
		"color": Color(0.38, 0.42, 0.32)
	}
}

func _ready() -> void:
	_init_default_rosters()
	_init_franchises()
	load_all_data()

func _init_default_rosters() -> void:
	teams["IND"] = {
		"id": "IND",
		"name": "India",
		"short_name": "IND",
		"primary_color": Color(0.04, 0.25, 0.65),
		"accent_color": Color(0.98, 0.55, 0.10),
		"slogan": "Bleed Blue",
		"players": [
			{"name": "R. Sharma", "number": 45, "role": "BATSMAN", "rating": 94, "batting": 96, "bowling": 35, "hand": "RIGHT"},
			{"name": "S. Gill", "number": 77, "role": "BATSMAN", "rating": 89, "batting": 90, "bowling": 25, "hand": "RIGHT"},
			{"name": "V. Kohli", "number": 18, "role": "BATSMAN", "rating": 97, "batting": 98, "bowling": 40, "hand": "RIGHT"},
			{"name": "S. Yadav", "number": 63, "role": "BATSMAN", "rating": 93, "batting": 95, "bowling": 30, "hand": "RIGHT"},
			{"name": "R. Pant", "number": 17, "role": "WICKETKEEPER", "rating": 91, "batting": 92, "bowling": 20, "hand": "LEFT"},
			{"name": "H. Pandya", "number": 33, "role": "ALL_ROUNDER", "rating": 90, "batting": 88, "bowling": 87, "hand": "RIGHT"},
			{"name": "R. Jadeja", "number": 8, "role": "ALL_ROUNDER", "rating": 92, "batting": 85, "bowling": 91, "hand": "LEFT"},
			{"name": "A. Patel", "number": 20, "role": "ALL_ROUNDER", "rating": 88, "batting": 82, "bowling": 89, "hand": "LEFT"},
			{"name": "K. Yadav", "number": 23, "role": "BOWLER", "rating": 91, "batting": 30, "bowling": 94, "hand": "LEFT", "style": "LEFT_ARM_SPIN"},
			{"name": "J. Bumrah", "number": 93, "role": "BOWLER", "rating": 98, "batting": 25, "bowling": 99, "hand": "RIGHT", "style": "RIGHT_ARM_FAST"},
			{"name": "M. Siraj", "number": 73, "role": "BOWLER", "rating": 89, "batting": 20, "bowling": 90, "hand": "RIGHT", "style": "RIGHT_ARM_FAST"}
		]
	}

	teams["AUS"] = {
		"id": "AUS",
		"name": "Australia",
		"short_name": "AUS",
		"primary_color": Color(0.92, 0.78, 0.12),
		"accent_color": Color(0.08, 0.38, 0.22),
		"slogan": "Aussie Spirit",
		"players": [
			{"name": "T. Head", "number": 62, "role": "BATSMAN", "rating": 93, "batting": 95, "bowling": 50, "hand": "LEFT"},
			{"name": "D. Warner", "number": 31, "role": "BATSMAN", "rating": 91, "batting": 92, "bowling": 20, "hand": "LEFT"},
			{"name": "M. Marsh", "number": 8, "role": "ALL_ROUNDER", "rating": 89, "batting": 89, "bowling": 82, "hand": "RIGHT"},
			{"name": "S. Smith", "number": 49, "role": "BATSMAN", "rating": 95, "batting": 96, "bowling": 45, "hand": "RIGHT"},
			{"name": "G. Maxwell", "number": 32, "role": "ALL_ROUNDER", "rating": 92, "batting": 93, "bowling": 85, "hand": "RIGHT"},
			{"name": "M. Stoinis", "number": 17, "role": "ALL_ROUNDER", "rating": 87, "batting": 86, "bowling": 83, "hand": "RIGHT"},
			{"name": "J. Inglis", "number": 48, "role": "WICKETKEEPER", "rating": 86, "batting": 87, "bowling": 20, "hand": "RIGHT"},
			{"name": "P. Cummins", "number": 30, "role": "BOWLER", "rating": 95, "batting": 75, "bowling": 96, "hand": "RIGHT", "style": "RIGHT_ARM_FAST"},
			{"name": "M. Starc", "number": 56, "role": "BOWLER", "rating": 94, "batting": 50, "bowling": 95, "hand": "LEFT", "style": "LEFT_ARM_FAST"},
			{"name": "A. Zampa", "number": 88, "role": "BOWLER", "rating": 90, "batting": 25, "bowling": 92, "hand": "RIGHT", "style": "RIGHT_ARM_SPIN"},
			{"name": "J. Hazlewood", "number": 38, "role": "BOWLER", "rating": 93, "batting": 20, "bowling": 94, "hand": "RIGHT", "style": "RIGHT_ARM_FAST"}
		]
	}

	teams["ENG"] = {
		"id": "ENG",
		"name": "England",
		"short_name": "ENG",
		"primary_color": Color(0.12, 0.40, 0.85),
		"accent_color": Color(0.85, 0.15, 0.15),
		"slogan": "Three Lions",
		"players": [
			{"name": "P. Salt", "number": 28, "role": "BATSMAN", "rating": 89, "batting": 91, "bowling": 20, "hand": "RIGHT"},
			{"name": "J. Buttler", "number": 63, "role": "WICKETKEEPER", "rating": 95, "batting": 96, "bowling": 20, "hand": "RIGHT"},
			{"name": "J. Bairstow", "number": 51, "role": "BATSMAN", "rating": 88, "batting": 90, "bowling": 20, "hand": "RIGHT"},
			{"name": "H. Brook", "number": 88, "role": "BATSMAN", "rating": 90, "batting": 92, "bowling": 30, "hand": "RIGHT"},
			{"name": "L. Livingstone", "number": 23, "role": "ALL_ROUNDER", "rating": 88, "batting": 88, "bowling": 84, "hand": "RIGHT"},
			{"name": "M. Ali", "number": 18, "role": "ALL_ROUNDER", "rating": 87, "batting": 85, "bowling": 85, "hand": "LEFT"},
			{"name": "S. Curran", "number": 58, "role": "ALL_ROUNDER", "rating": 88, "batting": 82, "bowling": 88, "hand": "LEFT"},
			{"name": "C. Jordan", "number": 34, "role": "BOWLER", "rating": 85, "batting": 60, "bowling": 86, "hand": "RIGHT", "style": "RIGHT_ARM_FAST"},
			{"name": "J. Archer", "number": 22, "role": "BOWLER", "rating": 93, "batting": 45, "bowling": 95, "hand": "RIGHT", "style": "RIGHT_ARM_FAST"},
			{"name": "A. Rashid", "number": 95, "role": "BOWLER", "rating": 91, "batting": 30, "bowling": 93, "hand": "RIGHT", "style": "RIGHT_ARM_SPIN"},
			{"name": "M. Wood", "number": 33, "role": "BOWLER", "rating": 90, "batting": 25, "bowling": 92, "hand": "RIGHT", "style": "RIGHT_ARM_FAST"}
		]
	}

	teams["PAK"] = {
		"id": "PAK",
		"name": "Pakistan",
		"short_name": "PAK",
		"primary_color": Color(0.06, 0.42, 0.22),
		"accent_color": Color(0.85, 0.85, 0.25),
		"slogan": "Cornered Tigers",
		"players": [
			{"name": "B. Azam", "number": 56, "role": "BATSMAN", "rating": 94, "batting": 96, "bowling": 20, "hand": "RIGHT"},
			{"name": "M. Rizwan", "number": 16, "role": "WICKETKEEPER", "rating": 92, "batting": 93, "bowling": 20, "hand": "RIGHT"},
			{"name": "F. Zaman", "number": 39, "role": "BATSMAN", "rating": 88, "batting": 90, "bowling": 25, "hand": "LEFT"},
			{"name": "I. Ahmed", "number": 95, "role": "ALL_ROUNDER", "rating": 85, "batting": 85, "bowling": 78, "hand": "RIGHT"},
			{"name": "S. Khan", "number": 7, "role": "ALL_ROUNDER", "rating": 89, "batting": 84, "bowling": 89, "hand": "RIGHT"},
			{"name": "I. Wasim", "number": 9, "role": "ALL_ROUNDER", "rating": 86, "batting": 81, "bowling": 86, "hand": "LEFT"},
			{"name": "N. Shah", "number": 71, "role": "BOWLER", "rating": 91, "batting": 30, "bowling": 93, "hand": "RIGHT", "style": "RIGHT_ARM_FAST"},
			{"name": "S. Afridi", "number": 10, "role": "BOWLER", "rating": 95, "batting": 50, "bowling": 96, "hand": "LEFT", "style": "LEFT_ARM_FAST"},
			{"name": "H. Rauf", "number": 150, "role": "BOWLER", "rating": 90, "batting": 20, "bowling": 92, "hand": "RIGHT", "style": "RIGHT_ARM_FAST"},
			{"name": "A. Jamal", "number": 65, "role": "ALL_ROUNDER", "rating": 84, "batting": 78, "bowling": 84, "hand": "RIGHT"},
			{"name": "A. Ahmed", "number": 40, "role": "BOWLER", "rating": 86, "batting": 15, "bowling": 88, "hand": "RIGHT", "style": "RIGHT_ARM_SPIN"}
		]
	}

	teams["SA"] = {
		"id": "SA",
		"name": "South Africa",
		"short_name": "SA",
		"primary_color": Color(0.08, 0.45, 0.28),
		"accent_color": Color(0.95, 0.75, 0.15),
		"slogan": "Protea Fire",
		"players": [
			{"name": "Q. de Kock", "number": 12, "role": "WICKETKEEPER", "rating": 92, "batting": 94, "bowling": 10, "hand": "LEFT"},
			{"name": "R. Hendricks", "number": 17, "role": "BATSMAN", "rating": 86, "batting": 88, "bowling": 20, "hand": "RIGHT"},
			{"name": "A. Markram", "number": 4, "role": "ALL_ROUNDER", "rating": 90, "batting": 91, "bowling": 80, "hand": "RIGHT"},
			{"name": "H. Klaasen", "number": 45, "role": "BATSMAN", "rating": 94, "batting": 96, "bowling": 20, "hand": "RIGHT"},
			{"name": "D. Miller", "number": 10, "role": "BATSMAN", "rating": 91, "batting": 93, "bowling": 20, "hand": "LEFT"},
			{"name": "T. Stubbs", "number": 30, "role": "BATSMAN", "rating": 88, "batting": 89, "bowling": 30, "hand": "RIGHT"},
			{"name": "M. Jansen", "number": 70, "role": "ALL_ROUNDER", "rating": 89, "batting": 80, "bowling": 90, "hand": "LEFT"},
			{"name": "K. Maharaj", "number": 16, "role": "BOWLER", "rating": 89, "batting": 45, "bowling": 91, "hand": "LEFT", "style": "LEFT_ARM_SPIN"},
			{"name": "K. Rabada", "number": 25, "role": "BOWLER", "rating": 94, "batting": 40, "bowling": 95, "hand": "RIGHT", "style": "RIGHT_ARM_FAST"},
			{"name": "A. Nortje", "number": 20, "role": "BOWLER", "rating": 92, "batting": 20, "bowling": 94, "hand": "RIGHT", "style": "RIGHT_ARM_FAST"},
			{"name": "T. Shamsi", "number": 26, "role": "BOWLER", "rating": 88, "batting": 15, "bowling": 90, "hand": "LEFT", "style": "LEFT_ARM_SPIN"}
		]
	}

	teams["NZ"] = {
		"id": "NZ",
		"name": "New Zealand",
		"short_name": "NZ",
		"primary_color": Color(0.12, 0.12, 0.14),
		"accent_color": Color(0.85, 0.85, 0.90),
		"slogan": "Black Caps",
		"players": [
			{"name": "D. Conway", "number": 88, "role": "WICKETKEEPER", "rating": 90, "batting": 92, "bowling": 10, "hand": "LEFT"},
			{"name": "F. Allen", "number": 23, "role": "BATSMAN", "rating": 87, "batting": 89, "bowling": 20, "hand": "RIGHT"},
			{"name": "K. Williamson", "number": 22, "role": "BATSMAN", "rating": 95, "batting": 96, "bowling": 35, "hand": "RIGHT"},
			{"name": "D. Mitchell", "number": 75, "role": "ALL_ROUNDER", "rating": 91, "batting": 92, "bowling": 79, "hand": "RIGHT"},
			{"name": "G. Phillips", "number": 23, "role": "ALL_ROUNDER", "rating": 89, "batting": 88, "bowling": 82, "hand": "RIGHT"},
			{"name": "M. Santner", "number": 74, "role": "ALL_ROUNDER", "rating": 89, "batting": 81, "bowling": 91, "hand": "LEFT"},
			{"name": "J. Neesham", "number": 50, "role": "ALL_ROUNDER", "rating": 86, "batting": 85, "bowling": 82, "hand": "LEFT"},
			{"name": "T. Southee", "number": 38, "role": "BOWLER", "rating": 90, "batting": 45, "bowling": 91, "hand": "RIGHT", "style": "RIGHT_ARM_FAST"},
			{"name": "M. Henry", "number": 21, "role": "BOWLER", "rating": 89, "batting": 30, "bowling": 91, "hand": "RIGHT", "style": "RIGHT_ARM_FAST"},
			{"name": "T. Boult", "number": 18, "role": "BOWLER", "rating": 93, "batting": 25, "bowling": 94, "hand": "LEFT", "style": "LEFT_ARM_FAST"},
			{"name": "L. Ferguson", "number": 69, "role": "BOWLER", "rating": 90, "batting": 20, "bowling": 92, "hand": "RIGHT", "style": "RIGHT_ARM_FAST"}
		]
	}

	teams["WI"] = {
		"id": "WI",
		"name": "West Indies",
		"short_name": "WI",
		"primary_color": Color(0.48, 0.08, 0.15),
		"accent_color": Color(0.95, 0.78, 0.12),
		"slogan": "Rally 'Round",
		"players": [
			{"name": "B. King", "number": 53, "role": "BATSMAN", "rating": 86, "batting": 88, "bowling": 15, "hand": "RIGHT"},
			{"name": "J. Charles", "number": 25, "role": "BATSMAN", "rating": 85, "batting": 87, "bowling": 15, "hand": "RIGHT"},
			{"name": "N. Pooran", "number": 29, "role": "WICKETKEEPER", "rating": 93, "batting": 95, "bowling": 15, "hand": "LEFT"},
			{"name": "S. Hope", "number": 4, "role": "BATSMAN", "rating": 89, "batting": 91, "bowling": 15, "hand": "RIGHT"},
			{"name": "R. Powell", "number": 52, "role": "BATSMAN", "rating": 88, "batting": 90, "bowling": 40, "hand": "RIGHT"},
			{"name": "A. Russell", "number": 12, "role": "ALL_ROUNDER", "rating": 93, "batting": 94, "bowling": 88, "hand": "RIGHT"},
			{"name": "R. Shepherd", "number": 93, "role": "ALL_ROUNDER", "rating": 87, "batting": 84, "bowling": 85, "hand": "RIGHT"},
			{"name": "A. Hosein", "number": 7, "role": "BOWLER", "rating": 89, "batting": 45, "bowling": 90, "hand": "LEFT", "style": "LEFT_ARM_SPIN"},
			{"name": "A. Joseph", "number": 8, "role": "BOWLER", "rating": 90, "batting": 30, "bowling": 92, "hand": "RIGHT", "style": "RIGHT_ARM_FAST"},
			{"name": "G. Motie", "number": 64, "role": "BOWLER", "rating": 88, "batting": 25, "bowling": 89, "hand": "LEFT", "style": "LEFT_ARM_SPIN"},
			{"name": "O. Thomas", "number": 42, "role": "BOWLER", "rating": 85, "batting": 15, "bowling": 87, "hand": "RIGHT", "style": "RIGHT_ARM_FAST"}
		]
	}

	teams["SL"] = {
		"id": "SL",
		"name": "Sri Lanka",
		"short_name": "SL",
		"primary_color": Color(0.08, 0.22, 0.55),
		"accent_color": Color(0.92, 0.72, 0.15),
		"slogan": "Lions",
		"players": [
			{"name": "P. Nissanka", "number": 18, "role": "BATSMAN", "rating": 89, "batting": 91, "bowling": 15, "hand": "RIGHT"},
			{"name": "K. Mendis", "number": 13, "role": "WICKETKEEPER", "rating": 88, "batting": 90, "bowling": 15, "hand": "RIGHT"},
			{"name": "C. Asalanka", "number": 72, "role": "BATSMAN", "rating": 87, "batting": 88, "bowling": 50, "hand": "LEFT"},
			{"name": "S. Samarawickrama", "number": 23, "role": "BATSMAN", "rating": 85, "batting": 86, "bowling": 15, "hand": "RIGHT"},
			{"name": "W. Hasaranga", "number": 49, "role": "ALL_ROUNDER", "rating": 93, "batting": 84, "bowling": 94, "hand": "RIGHT", "style": "RIGHT_ARM_SPIN"},
			{"name": "D. Shanaka", "number": 7, "role": "ALL_ROUNDER", "rating": 86, "batting": 85, "bowling": 80, "hand": "RIGHT"},
			{"name": "A. Mathews", "number": 69, "role": "ALL_ROUNDER", "rating": 87, "batting": 87, "bowling": 81, "hand": "RIGHT"},
			{"name": "M. Theekshana", "number": 61, "role": "BOWLER", "rating": 90, "batting": 25, "bowling": 92, "hand": "RIGHT", "style": "RIGHT_ARM_SPIN"},
			{"name": "D. Madushanka", "number": 98, "role": "BOWLER", "rating": 88, "batting": 15, "bowling": 90, "hand": "LEFT", "style": "LEFT_ARM_FAST"},
			{"name": "M. Pathirana", "number": 81, "role": "BOWLER", "rating": 91, "batting": 15, "bowling": 93, "hand": "RIGHT", "style": "RIGHT_ARM_FAST"},
			{"name": "D. Chameera", "number": 5, "role": "BOWLER", "rating": 86, "batting": 20, "bowling": 88, "hand": "RIGHT", "style": "RIGHT_ARM_FAST"}
		]
	}

func _init_franchises() -> void:
	franchises["MB"] = {
		"id": "MB",
		"name": "Mumbai Blasters",
		"purse": 100000000,
		"primary_color": Color(0.05, 0.35, 0.75),
		"accent_color": Color(0.95, 0.75, 0.10),
		"roster": []
	}
	franchises["CSK"] = {
		"id": "CSK",
		"name": "Chennai Super Kings",
		"purse": 100000000,
		"primary_color": Color(0.95, 0.82, 0.10),
		"accent_color": Color(0.10, 0.45, 0.85),
		"roster": []
	}
	franchises["BT"] = {
		"id": "BT",
		"name": "Bangalore Titans",
		"purse": 100000000,
		"primary_color": Color(0.85, 0.12, 0.15),
		"accent_color": Color(0.12, 0.12, 0.12),
		"roster": []
	}
	franchises["KK"] = {
		"id": "KK",
		"name": "Kolkata Knights",
		"purse": 100000000,
		"primary_color": Color(0.32, 0.12, 0.55),
		"accent_color": Color(0.92, 0.78, 0.20),
		"roster": []
	}

func save_all_data() -> void:
	var save_dict: Dictionary = {
		"profile": profile,
		"custom_player": custom_player
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_dict, "\t"))
		file.close()

func load_all_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save_all_data()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_str := file.get_as_text()
		file.close()
		var json := JSON.new()
		var parse_result := json.parse(json_str)
		if parse_result == OK and json.data is Dictionary:
			var data: Dictionary = json.data
			if data.has("profile"):
				profile.merge(data["profile"], true)
			if data.has("custom_player"):
				custom_player.merge(data["custom_player"], true)

func get_team(team_id: String) -> Dictionary:
	if teams.has(team_id):
		return teams[team_id]
	return teams["IND"]

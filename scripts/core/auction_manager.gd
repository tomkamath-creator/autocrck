# scripts/core/auction_manager.gd
# Mega Auction Mode Engine for CricStrike 3D
# Franchise budget management, AI bidding wars, player auction pool, and roster building.
extends Node

signal player_introduced(player: Dictionary)
signal bid_placed(team_name: String, amount: int)
signal hammer_struck(winner_team: String, player: Dictionary, final_amount: int)
signal auction_concluded()

var user_franchise: String = "Mumbai Titans"
var user_purse: int = 100000000 # 100 Crores (100M)
var franchises: Dictionary = {
	"Mumbai Titans": {"purse": 100000000, "squad": []},
	"Bangalore Challengers": {"purse": 100000000, "squad": []},
	"Chennai Kings": {"purse": 100000000, "squad": []},
	"Delhi Dynamos": {"purse": 100000000, "squad": []}
}

var auction_pool: Array[Dictionary] = [
	{"name": "V. Kohli", "role": "Batsman", "rating": 96, "base_price": 20000000},
	{"name": "J. Bumrah", "role": "Bowler", "rating": 98, "base_price": 20000000},
	{"name": "R. Sharma", "role": "Batsman", "rating": 92, "base_price": 20000000},
	{"name": "P. Cummins", "role": "All-Rounder", "rating": 95, "base_price": 20000000},
	{"name": "M. Starc", "role": "Bowler", "rating": 94, "base_price": 20000000},
	{"name": "H. Pandya", "role": "All-Rounder", "rating": 88, "base_price": 15000000},
	{"name": "R. Pant", "role": "Wicketkeeper", "rating": 89, "base_price": 15000000},
	{"name": "T. Head", "role": "Batsman", "rating": 91, "base_price": 15000000},
	{"name": "H. Klaasen", "role": "Batsman", "rating": 93, "base_price": 15000000},
	{"name": "K. Rabada", "role": "Bowler", "rating": 95, "base_price": 15000000},
	{"name": "R. Jadeja", "role": "All-Rounder", "rating": 89, "base_price": 15000000},
	{"name": "J. Buttler", "role": "Wicketkeeper", "rating": 92, "base_price": 15000000},
	{"name": "S. Gill", "role": "Batsman", "rating": 88, "base_price": 10000000},
	{"name": "S. Yadav", "role": "Batsman", "rating": 90, "base_price": 10000000},
	{"name": "G. Maxwell", "role": "All-Rounder", "rating": 89, "base_price": 10000000},
	{"name": "A. Zampa", "role": "Bowler", "rating": 90, "base_price": 10000000},
	{"name": "J. Archer", "role": "Bowler", "rating": 92, "base_price": 10000000},
	{"name": "Q. de Kock", "role": "Wicketkeeper", "rating": 90, "base_price": 10000000},
	{"name": "M. Siraj", "role": "Bowler", "rating": 88, "base_price": 8000000},
	{"name": "K. Yadav", "role": "Bowler", "rating": 91, "base_price": 8000000}
]

var current_player_index: int = 0
var current_player: Dictionary = {}
var current_bid: int = 0
var current_bidder: String = ""
var auction_timer: float = 0.0
var hammer_countdown: int = 3
var is_auction_active: bool = false

func start_auction(user_team: String = "Mumbai Titans") -> void:
	user_franchise = user_team
	current_player_index = 0
	is_auction_active = true
	_introduce_next_player()

func _introduce_next_player() -> void:
	if current_player_index >= auction_pool.size():
		is_auction_active = false
		emit_signal("auction_concluded")
		return
	
	current_player = auction_pool[current_player_index]
	current_bid = current_player["base_price"]
	current_bidder = ""
	hammer_countdown = 3
	emit_signal("player_introduced", current_player)

func place_user_bid() -> bool:
	if not is_auction_active:
		return false
	
	var increment = 2500000 if current_bid < 50000000 else 5000000
	var next_bid = current_bid + increment
	
	if franchises[user_franchise]["purse"] < next_bid:
		return false # Insufficient purse
	
	current_bid = next_bid
	current_bidder = user_franchise
	hammer_countdown = 3
	AudioManager.play_ui_click()
	emit_signal("bid_placed", user_franchise, current_bid)
	return true

func update_auction(delta: float) -> void:
	if not is_auction_active:
		return
	
	auction_timer += delta
	if auction_timer >= 1.4:
		auction_timer = 0.0
		_process_ai_or_hammer()

func _process_ai_or_hammer() -> void:
	# Check if an AI team wants to outbid
	var ai_bid_made = false
	var ai_teams = ["Bangalore Challengers", "Chennai Kings", "Delhi Dynamos", "Mumbai Titans"]
	ai_teams.erase(user_franchise)
	ai_teams.erase(current_bidder)
	
	var candidate_team = ai_teams[randi() % ai_teams.size()]
	var team_data = franchises[candidate_team]
	var max_willing = current_player["rating"] * 1800000 # Higher rated players command higher bids
	
	var increment = 2500000 if current_bid < 50000000 else 5000000
	var next_bid = current_bid + increment
	
	if next_bid <= max_willing and team_data["purse"] >= next_bid and randf() > 0.35:
		current_bid = next_bid
		current_bidder = candidate_team
		hammer_countdown = 3
		ai_bid_made = true
		AudioManager.play_ui_click()
		emit_signal("bid_placed", candidate_team, current_bid)
	
	if not ai_bid_made and current_bidder != "":
		hammer_countdown -= 1
		if hammer_countdown <= 0:
			# SOLD!
			_sell_player_to_highest_bidder()

func _sell_player_to_highest_bidder() -> void:
	franchises[current_bidder]["purse"] -= current_bid
	franchises[current_bidder]["squad"].append(current_player)
	
	AudioManager.play_bat_crack(true) # Sound of auctioneer gavel / hammer!
	emit_signal("hammer_struck", current_bidder, current_player, current_bid)
	
	current_player_index += 1
	# Give 2 seconds display then next player
	_introduce_next_player()

func format_currency(amount: int) -> String:
	# Formats into Crores or Lakhs
	if amount >= 10000000:
		var cr = float(amount) / 10000000.0
		return "₹ " + str(snapped(cr, 0.01)) + " Cr"
	else:
		var lk = float(amount) / 100000.0
		return "₹ " + str(snapped(lk, 0.1)) + " L"

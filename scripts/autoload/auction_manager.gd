extends Node

# AuctionManager: Offline Franchise Mega Auction Engine

signal bid_updated(player: Dictionary, current_bid: int, bidder: String)
signal player_sold(player: Dictionary, winning_bid: int, buyer: String)
signal auction_ended()

var user_franchise_id: String = "MB"
var franchise_purses: Dictionary = {
	"MB": 100000000,
	"CSK": 100000000,
	"BT": 100000000,
	"KK": 100000000
}

var franchise_squads: Dictionary = {
	"MB": [],
	"CSK": [],
	"BT": [],
	"KK": []
}

var auction_pool: Array[Dictionary] = [
	{"name": "H. Klaasen", "role": "BATSMAN", "rating": 94, "base_price": 20000000},
	{"name": "M. Starc", "role": "BOWLER", "rating": 94, "base_price": 20000000},
	{"name": "P. Cummins", "role": "ALL_ROUNDER", "rating": 95, "base_price": 20000000},
	{"name": "N. Pooran", "role": "WICKETKEEPER", "rating": 93, "base_price": 15000000},
	{"name": "A. Russell", "role": "ALL_ROUNDER", "rating": 93, "base_price": 20000000},
	{"name": "J. Archer", "role": "BOWLER", "rating": 93, "base_price": 20000000},
	{"name": "T. Head", "role": "BATSMAN", "rating": 93, "base_price": 15000000},
	{"name": "W. Hasaranga", "role": "ALL_ROUNDER", "rating": 93, "base_price": 15000000},
	{"name": "G. Maxwell", "role": "ALL_ROUNDER", "rating": 92, "base_price": 15000000},
	{"name": "S. Afridi", "role": "BOWLER", "rating": 95, "base_price": 20000000},
	{"name": "Q. de Kock", "role": "WICKETKEEPER", "rating": 92, "base_price": 15000000},
	{"name": "K. Rabada", "role": "BOWLER", "rating": 94, "base_price": 20000000}
]

var current_player_idx: int = 0
var current_bid: int = 0
var current_bidder: String = "None"
var countdown_timer: float = 4.0
var auction_active: bool = false

func init_auction(selected_franchise: String) -> void:
	user_franchise_id = selected_franchise
	for f in franchise_purses.keys():
		franchise_purses[f] = 100000000
		franchise_squads[f] = []
	current_player_idx = 0
	auction_active = true
	_present_next_player()

func _present_next_player() -> void:
	if current_player_idx >= auction_pool.size():
		auction_active = false
		auction_ended.emit()
		return
	
	var p: Dictionary = auction_pool[current_player_idx]
	current_bid = p["base_price"]
	current_bidder = "None"
	countdown_timer = 4.0
	bid_updated.emit(p, current_bid, current_bidder)

func place_user_bid() -> bool:
	if not auction_active or current_player_idx >= auction_pool.size():
		return false
	
	var increment: int = 2500000 if current_bid < 50000000 else 5000000
	var new_bid: int = current_bid + increment
	
	if franchise_purses[user_franchise_id] >= new_bid:
		current_bid = new_bid
		current_bidder = user_franchise_id
		countdown_timer = 4.0
		bid_updated.emit(auction_pool[current_player_idx], current_bid, current_bidder)
		AudioManager.play_sfx("bat_crack", 1.2) # Crisp gavel tap
		return true
	return false

func process_auction_ai(delta: float) -> void:
	if not auction_active or current_player_idx >= auction_pool.size():
		return
		
	countdown_timer -= delta
	
	# AI teams consider bidding
	if countdown_timer < 3.0 and randf() < 0.25 and current_bidder != "None":
		var ai_franchises: Array = ["MB", "CSK", "BT", "KK"]
		ai_franchises.erase(current_bidder)
		var bidder: String = ai_franchises[randi() % ai_franchises.size()]
		var increment: int = 2500000 if current_bid < 50000000 else 5000000
		var potential_bid: int = current_bid + increment
		
		var max_val: int = int(auction_pool[current_player_idx]["rating"] * 800000)
		if franchise_purses[bidder] >= potential_bid and potential_bid <= max_val:
			current_bid = potential_bid
			current_bidder = bidder
			countdown_timer = 3.5
			bid_updated.emit(auction_pool[current_player_idx], current_bid, current_bidder)
			AudioManager.play_sfx("bat_crack", 1.1)

	if countdown_timer <= 0.0:
		_finalize_sale()

func _finalize_sale() -> void:
	var p: Dictionary = auction_pool[current_player_idx]
	if current_bidder != "None":
		franchise_purses[current_bidder] -= current_bid
		franchise_squads[current_bidder].append(p)
		player_sold.emit(p, current_bid, current_bidder)
		AudioManager.play_sfx("crowd_cheer", 0.9)
	else:
		player_sold.emit(p, 0, "UNSOLD")
	
	current_player_idx += 1
	_present_next_player()

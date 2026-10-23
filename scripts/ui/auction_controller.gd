# scripts/ui/auction_controller.gd
# Mega Auction Franchise Bidding Controller for CricStrike 3D
extends Control

@onready var label_purse: Label = $Header/PurseLabel
@onready var label_player_card: Label = $PlayerPodium/PlayerInfo
@onready var label_current_bid: Label = $BiddingArea/CurrentBidLabel
@onready var label_bidder: Label = $BiddingArea/HighestBidderLabel
@onready var label_countdown: Label = $BiddingArea/HammerCountdownLabel
@onready var btn_bid: Button = $BiddingArea/BtnPlaceBid
@onready var btn_back: Button = $BtnBack
@onready var log_label: Label = $SquadListPanel/SquadLogLabel

func _ready() -> void:
	_connect_events()
	_update_view()

func _process(delta: float) -> void:
	AuctionManager.update_auction(delta)

func _connect_events() -> void:
	AuctionManager.player_introduced.connect(_on_player_introduced)
	AuctionManager.bid_placed.connect(_on_bid_placed)
	AuctionManager.hammer_struck.connect(_on_hammer_struck)
	AuctionManager.auction_concluded.connect(_on_auction_concluded)
	
	if btn_bid: btn_bid.pressed.connect(_on_bid_button_pressed)
	if btn_back: btn_back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))

func _update_view() -> void:
	var team_data = AuctionManager.franchises.get(AuctionManager.user_franchise, {})
	var purse = team_data.get("purse", 100000000)
	if label_purse:
		label_purse.text = "YOUR PURSE: " + AuctionManager.format_currency(purse)

func _on_player_introduced(player: Dictionary) -> void:
	if label_player_card:
		label_player_card.text = player["name"].to_upper() + "\nROLE: " + player["role"] + "  |  RATING: " + str(player["rating"]) + "\nBASE PRICE: " + AuctionManager.format_currency(player["base_price"])
	if label_current_bid:
		label_current_bid.text = "OPENING BID: " + AuctionManager.format_currency(player["base_price"])
	if label_bidder:
		label_bidder.text = "WAITING FOR BIDS..."
	if label_countdown:
		label_countdown.text = ""

func _on_bid_placed(team_name: String, amount: int) -> void:
	if label_current_bid:
		label_current_bid.text = "CURRENT BID: " + AuctionManager.format_currency(amount)
	if label_bidder:
		label_bidder.text = "HIGHEST BIDDER: " + team_name.to_upper()
	if label_countdown:
		label_countdown.text = "BID ACTIVE!"
	_update_view()

func _on_hammer_struck(winner: String, player: Dictionary, final_amt: int) -> void:
	if label_countdown:
		label_countdown.text = "🔨 SOLD TO " + winner.to_upper() + " FOR " + AuctionManager.format_currency(final_amt) + "!"
	
	# Update squad log
	if log_label and winner == AuctionManager.user_franchise:
		log_label.text += player["name"] + " (" + player["role"] + ") - " + AuctionManager.format_currency(final_amt) + "\n"
	
	_update_view()

func _on_auction_concluded() -> void:
	if label_player_card:
		label_player_card.text = "AUCTION CONCLUDED!\nALL SQUADS FINALIZED"
	if btn_bid:
		btn_bid.disabled = true

func _on_bid_button_pressed() -> void:
	var success = AuctionManager.place_user_bid()
	if not success:
		if label_countdown:
			label_countdown.text = "INSUFFICIENT PURSE!"

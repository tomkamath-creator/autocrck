# scripts/ui/main_menu_controller.gd
# Main Menu & Game Mode Selection Controller for CricStrike 3D
extends Control

@onready var label_player_info: Label = $Header/PlayerInfoLabel
@onready var label_coins: Label = $Header/CoinsLabel
@onready var quick_match_panel: Panel = $QuickMatchPopup

# Quick match options
var selected_overs: int = 5
var selected_pitch: int = 2 # Flat Deck
var selected_team_user: String = "India"
var selected_team_ai: String = "Australia"
var selected_difficulty: String = "Medium"

func _ready() -> void:
	_update_header()
	if quick_match_panel: quick_match_panel.visible = false
	_connect_menu_buttons()

func _update_header() -> void:
	var prof = PersistenceManager.profile_data
	if label_player_info:
		label_player_info.text = prof.get("player_name", "Champion") + " (LVL " + str(prof.get("level", 1)) + ")"
	if label_coins:
		label_coins.text = "🪙 " + str(prof.get("coins", 5000)) + "  |  🏆 " + str(prof.get("trophies", 0))

func _connect_menu_buttons() -> void:
	var btn_qm = $ModeContainer/BtnQuickMatch
	var btn_so = $ModeContainer/BtnSuperOver
	var btn_wt = $ModeContainer/BtnWorldTournament
	var btn_ma = $ModeContainer/BtnMegaAuction
	var btn_lr = $ModeContainer/BtnLockerRoom
	
	if btn_qm: btn_qm.pressed.connect(_on_quick_match_pressed)
	if btn_so: btn_so.pressed.connect(_on_super_over_pressed)
	if btn_wt: btn_wt.pressed.connect(_on_world_tournament_pressed)
	if btn_ma: btn_ma.pressed.connect(_on_mega_auction_pressed)
	if btn_lr: btn_lr.pressed.connect(_on_locker_room_pressed)
	
	# Quick match popup buttons
	var btn_start_match = $QuickMatchPopup/BtnStartMatch
	var btn_close_popup = $QuickMatchPopup/BtnClosePopup
	if btn_start_match: btn_start_match.pressed.connect(_on_start_match_confirmed)
	if btn_close_popup: btn_close_popup.pressed.connect(func(): quick_match_panel.visible = false)

func _on_quick_match_pressed() -> void:
	AudioManager.play_ui_click()
	quick_match_panel.visible = true

func _on_super_over_pressed() -> void:
	AudioManager.play_ui_click()
	GameManager.start_new_match(GameManager.GameMode.SUPER_OVER, 1, 2, "India", "Australia", true)
	get_tree().change_scene_to_file("res://scenes/match.tscn")

func _on_world_tournament_pressed() -> void:
	AudioManager.play_ui_click()
	if not TournamentManager.fixtures_group.is_empty():
		get_tree().change_scene_to_file("res://scenes/tournament.tscn")
	else:
		TournamentManager.initialize_new_tournament("India")
		get_tree().change_scene_to_file("res://scenes/tournament.tscn")

func _on_mega_auction_pressed() -> void:
	AudioManager.play_ui_click()
	AuctionManager.start_auction("Mumbai Titans")
	get_tree().change_scene_to_file("res://scenes/auction.tscn")

func _on_locker_room_pressed() -> void:
	AudioManager.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/locker_room.tscn")

func _on_start_match_confirmed() -> void:
	AudioManager.play_ui_click()
	GameManager.start_new_match(GameManager.GameMode.QUICK_MATCH, selected_overs, selected_pitch, selected_team_user, selected_team_ai, true)
	get_tree().change_scene_to_file("res://scenes/match.tscn")

# scripts/ui/tournament_controller.gd
# World Tournament Standings, Fixtures & Knockout Bracket Controller
extends Control

@onready var table_label: Label = $PointsTablePanel/TableLabel
@onready var next_match_label: Label = $NextMatchPanel/MatchInfoLabel
@onready var btn_play: Button = $NextMatchPanel/BtnPlay
@onready var btn_sim: Button = $NextMatchPanel/BtnSimulate
@onready var btn_back: Button = $BtnBack

var active_fixture: Dictionary = {}

func _ready() -> void:
	_update_tournament_view()
	if btn_play: btn_play.pressed.connect(_on_play_pressed)
	if btn_sim: btn_sim.pressed.connect(_on_sim_pressed)
	if btn_back: btn_back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))

func _update_tournament_view() -> void:
	# Format Points Table
	var sorted_a = TournamentManager.get_sorted_table(TournamentManager.points_table_a)
	var text = "GROUP A STANDINGS\n"
	text += "TEAM                P   W   L   PTS   NRR\n"
	text += "----------------------------------------\n"
	for row in sorted_a:
		var name_padded = row["team"].rpad(18, " ")
		text += name_padded + " " + str(row["P"]) + "   " + str(row["W"]) + "   " + str(row["L"]) + "    " + str(row["PTS"]) + "   " + str(row["NRR"]) + "\n"
	
	text += "\nGROUP B STANDINGS\n"
	text += "TEAM                P   W   L   PTS   NRR\n"
	text += "----------------------------------------\n"
	var sorted_b = TournamentManager.get_sorted_table(TournamentManager.points_table_b)
	for row in sorted_b:
		var name_padded = row["team"].rpad(18, " ")
		text += name_padded + " " + str(row["P"]) + "   " + str(row["W"]) + "   " + str(row["L"]) + "    " + str(row["PTS"]) + "   " + str(row["NRR"]) + "\n"
	
	if table_label: table_label.text = text
	
	# Next Fixture
	active_fixture = TournamentManager.get_next_fixture()
	if not active_fixture.is_empty():
		var t1 = active_fixture.get("team1", "Team 1")
		var t2 = active_fixture.get("team2", "Team 2")
		var stage = active_fixture.get("stage", "Group Stage")
		if next_match_label:
			next_match_label.text = stage.to_upper() + "\n" + t1.to_upper() + "  vs  " + t2.to_upper()
		if btn_play: btn_play.disabled = false
		if btn_sim: btn_sim.disabled = false
	else:
		if next_match_label:
			next_match_label.text = "TOURNAMENT COMPLETED!\nCHAMPION: " + TournamentManager.tournament_winner.to_upper()
		if btn_play: btn_play.disabled = true
		if btn_sim: btn_sim.disabled = true

func _on_play_pressed() -> void:
	if active_fixture.is_empty():
		return
	AudioManager.play_ui_click()
	GameManager.start_new_match(GameManager.GameMode.WORLD_TOURNAMENT, 5, 2, active_fixture["team1"], active_fixture["team2"], true)
	get_tree().change_scene_to_file("res://scenes/match.tscn")

func _on_sim_pressed() -> void:
	if active_fixture.is_empty():
		return
	AudioManager.play_ui_click()
	TournamentManager.simulate_ai_match(active_fixture)
	_update_tournament_view()

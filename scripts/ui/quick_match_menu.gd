extends Control
class_name QuickMatchMenu

# QuickMatchMenu: Fast Exhibition Match Setup with Full Configuration

var team_a_keys: Array = ["IND", "AUS", "ENG", "PAK", "SA", "NZ", "WI", "SL"]
var team_a_idx: int = 0
var team_b_idx: int = 1

var overs_options: Array[int] = [2, 5, 10, 20, 50]
var overs_idx: int = 1 # 5 overs default

var pitch_keys: Array = ["GREEN_TURF", "DUSTY_PITCH", "FLAT_DECK", "WET_PITCH"]
var pitch_idx: int = 0

var difficulty_options: Array[String] = ["EASY", "MEDIUM", "HARD", "LEGEND"]
var diff_idx: int = 1

var team_a_btn: Button
var team_b_btn: Button
var overs_btn: Button
var pitch_btn: Button
var diff_btn: Button
var pitch_desc_lbl: Label

func _ready() -> void:
	_build_ui()
	_update_labels()

func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var bg := ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.07, 0.09, 0.14)
	add_child(bg)

	# Header
	var title := Label.new()
	title.text = "🏏 QUICK MATCH CONFIGURATION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.offset_top = 28
	title.anchor_right = 1.0
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	add_child(title)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -260
	panel.offset_top = -180
	panel.offset_right = 260
	panel.offset_bottom = 180
	var style_p := StyleBoxFlat.new()
	style_p.bg_color = Color(0.1, 0.14, 0.2, 0.95)
	style_p.corner_radius_top_left = 16
	style_p.corner_radius_top_right = 16
	style_p.corner_radius_bottom_left = 16
	style_p.corner_radius_bottom_right = 16
	panel.add_theme_stylebox_override("panel", style_p)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	panel.add_child(vbox)

	# Team Selection Row
	var hbox_teams := HBoxContainer.new()
	hbox_teams.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox_teams)

	team_a_btn = Button.new()
	team_a_btn.custom_minimum_size = Vector2(200, 48)
	team_a_btn.pressed.connect(func():
		team_a_idx = (team_a_idx + 1) % team_a_keys.size()
		_update_labels()
	)
	hbox_teams.add_child(team_a_btn)

	var vs_lbl := Label.new()
	vs_lbl.text = "  VS  "
	vs_lbl.add_theme_font_size_override("font_size", 20)
	vs_lbl.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	hbox_teams.add_child(vs_lbl)

	team_b_btn = Button.new()
	team_b_btn.custom_minimum_size = Vector2(200, 48)
	team_b_btn.pressed.connect(func():
		team_b_idx = (team_b_idx + 1) % team_a_keys.size()
		_update_labels()
	)
	hbox_teams.add_child(team_b_btn)

	# Overs & Difficulty Row
	var hbox_opts := HBoxContainer.new()
	hbox_opts.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_opts.add_theme_constant_override("separation", 16)
	vbox.add_child(hbox_opts)

	overs_btn = Button.new()
	overs_btn.custom_minimum_size = Vector2(210, 44)
	overs_btn.pressed.connect(func():
		overs_idx = (overs_idx + 1) % overs_options.size()
		_update_labels()
	)
	hbox_opts.add_child(overs_btn)

	diff_btn = Button.new()
	diff_btn.custom_minimum_size = Vector2(210, 44)
	diff_btn.pressed.connect(func():
		diff_idx = (diff_idx + 1) % difficulty_options.size()
		_update_labels()
	)
	hbox_opts.add_child(diff_btn)

	# Pitch Row
	pitch_btn = Button.new()
	pitch_btn.custom_minimum_size = Vector2(440, 44)
	pitch_btn.pressed.connect(func():
		pitch_idx = (pitch_idx + 1) % pitch_keys.size()
		_update_labels()
	)
	vbox.add_child(pitch_btn)

	pitch_desc_lbl = Label.new()
	pitch_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pitch_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	pitch_desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	vbox.add_child(pitch_desc_lbl)

	# Bottom Actions
	var hbox_action := HBoxContainer.new()
	hbox_action.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_action.add_theme_constant_override("separation", 24)
	hbox_action.anchor_left = 0.5
	hbox_action.anchor_top = 1.0
	hbox_action.anchor_right = 0.5
	hbox_action.anchor_bottom = 1.0
	hbox_action.offset_left = -220
	hbox_action.offset_top = -80
	hbox_action.offset_right = 220
	hbox_action.offset_bottom = -24
	add_child(hbox_action)

	var back_btn := Button.new()
	back_btn.text = "⬅ BACK"
	back_btn.custom_minimum_size = Vector2(160, 52)
	back_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	hbox_action.add_child(back_btn)

	var play_btn := Button.new()
	play_btn.text = "PLAY MATCH 🏏"
	play_btn.custom_minimum_size = Vector2(240, 52)
	var style_pl := StyleBoxFlat.new()
	style_pl.bg_color = Color(0.1, 0.65, 0.25)
	style_pl.corner_radius_top_left = 12
	style_pl.corner_radius_top_right = 12
	style_pl.corner_radius_bottom_left = 12
	style_pl.corner_radius_bottom_right = 12
	play_btn.add_theme_stylebox_override("normal", style_pl)
	play_btn.pressed.connect(_on_start_match)
	hbox_action.add_child(play_btn)

func _update_labels() -> void:
	var t_a: String = team_a_keys[team_a_idx]
	var t_b: String = team_a_keys[team_b_idx]
	team_a_btn.text = "TEAM: %s" % DataManager.get_team(t_a)["name"]
	team_b_btn.text = "TEAM: %s" % DataManager.get_team(t_b)["name"]
	overs_btn.text = "OVERS: %d" % overs_options[overs_idx]
	diff_btn.text = "DIFFICULTY: %s" % difficulty_options[diff_idx]

	var p_key: String = pitch_keys[pitch_idx]
	var p_data: Dictionary = DataManager.pitch_types[p_key]
	pitch_btn.text = "PITCH: %s" % p_data["name"]
	pitch_desc_lbl.text = p_data["description"]

func _on_start_match() -> void:
	var t_a: String = team_a_keys[team_a_idx]
	var t_b: String = team_a_keys[team_b_idx]
	var ov: int = overs_options[overs_idx]
	var p_key: String = pitch_keys[pitch_idx]
	var diff: String = difficulty_options[diff_idx]

	GameManager.setup_match(t_a, t_b, ov, p_key, diff, GameManager.GameMode.QUICK_MATCH)
	get_tree().change_scene_to_file("res://scenes/match.tscn")

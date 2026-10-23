extends Control
class_name TournamentMenu

# TournamentMenu: 8-Team World Championship Stage Hub with Live Points Table & NRR

var stage_label: Label
var fixture_label: Label
var table_vbox: VBoxContainer
var play_btn: Button
var sim_btn: Button

func _ready() -> void:
	if TournamentManager.fixtures.is_empty():
		TournamentManager.init_tournament("IND")
	
	TournamentManager.tournament_updated.connect(_update_view)
	_build_ui()
	_update_view()

func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var bg := ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.06, 0.08, 0.12)
	add_child(bg)

	# Header
	var header := PanelContainer.new()
	header.anchor_right = 1.0
	header.offset_bottom = 60
	var style_h := StyleBoxFlat.new()
	style_h.bg_color = Color(0.08, 0.12, 0.18)
	style_h.border_width_bottom = 2
	style_h.border_color = Color(0.85, 0.65, 0.1)
	header.add_theme_stylebox_override("panel", style_h)
	add_child(header)

	var hbox_h := HBoxContainer.new()
	hbox_h.offset_left = 20
	hbox_h.offset_right = -20
	header.add_child(hbox_h)

	var title := Label.new()
	title.text = "🏆 WORLD TOURNAMENT"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	hbox_h.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_h.add_child(spacer)

	stage_label = Label.new()
	stage_label.text = "STAGE: GROUP STAGE"
	stage_label.add_theme_font_size_override("font_size", 16)
	hbox_h.add_child(stage_label)

	# Points Table Container (Left Half)
	var left_panel := PanelContainer.new()
	left_panel.offset_left = 32
	left_panel.offset_top = 80
	left_panel.offset_right = 720
	left_panel.offset_bottom = 600
	var style_lp := StyleBoxFlat.new()
	style_lp.bg_color = Color(0.09, 0.12, 0.18, 0.95)
	style_lp.corner_radius_top_left = 12
	style_lp.corner_radius_top_right = 12
	style_lp.corner_radius_bottom_left = 12
	style_lp.corner_radius_bottom_right = 12
	left_panel.add_theme_stylebox_override("panel", style_lp)
	add_child(left_panel)

	var vbox_l := VBoxContainer.new()
	vbox_l.offset_left = 16
	vbox_l.offset_top = 16
	vbox_l.offset_right = -16
	vbox_l.offset_bottom = -16
	left_panel.add_child(vbox_l)

	var table_header := Label.new()
	table_header.text = "POINTS TABLE & NET RUN RATE (NRR)"
	table_header.add_theme_font_size_override("font_size", 16)
	table_header.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
	vbox_l.add_child(table_header)

	table_vbox = VBoxContainer.new()
	table_vbox.add_theme_constant_override("separation", 6)
	vbox_l.add_child(table_vbox)

	# Right Fixture Card
	var right_panel := PanelContainer.new()
	right_panel.offset_left = 750
	right_panel.offset_top = 80
	right_panel.offset_right = 1240
	right_panel.offset_bottom = 440
	var style_rp := StyleBoxFlat.new()
	style_rp.bg_color = Color(0.12, 0.16, 0.24, 0.95)
	style_rp.corner_radius_top_left = 12
	style_rp.corner_radius_top_right = 12
	style_rp.corner_radius_bottom_left = 12
	style_rp.corner_radius_bottom_right = 12
	right_panel.add_theme_stylebox_override("panel", style_rp)
	add_child(right_panel)

	var vbox_r := VBoxContainer.new()
	vbox_r.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_r.add_theme_constant_override("separation", 16)
	right_panel.add_child(vbox_r)

	var fix_title := Label.new()
	fix_title.text = "UPCOMING FIXTURE"
	fix_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fix_title.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1))
	vbox_r.add_child(fix_title)

	fixture_label = Label.new()
	fixture_label.text = "IND vs AUS"
	fixture_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fixture_label.add_theme_font_size_override("font_size", 24)
	vbox_r.add_child(fixture_label)

	play_btn = Button.new()
	play_btn.text = "PLAY FIXTURE 🏏"
	play_btn.custom_minimum_size = Vector2(280, 50)
	var style_pbtn := StyleBoxFlat.new()
	style_pbtn.bg_color = Color(0.1, 0.65, 0.25)
	style_pbtn.corner_radius_top_left = 10
	style_pbtn.corner_radius_top_right = 10
	style_pbtn.corner_radius_bottom_left = 10
	style_pbtn.corner_radius_bottom_right = 10
	play_btn.add_theme_stylebox_override("normal", style_pbtn)
	play_btn.pressed.connect(_on_play_fixture)
	vbox_r.add_child(play_btn)

	sim_btn = Button.new()
	sim_btn.text = "QUICK SIMULATE ⚡"
	sim_btn.custom_minimum_size = Vector2(280, 44)
	sim_btn.pressed.connect(_on_sim_fixture)
	vbox_r.add_child(sim_btn)

	# Bottom Back Button
	var back_btn := Button.new()
	back_btn.text = "⬅ BACK TO MENU"
	back_btn.offset_left = 750
	back_btn.offset_top = 540
	back_btn.offset_right = 1240
	back_btn.offset_bottom = 600
	back_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	add_child(back_btn)

func _update_view() -> void:
	stage_label.text = "STAGE: %s" % TournamentManager.current_stage

	# Clear table
	for child in table_vbox.get_children():
		child.queue_free()

	# Add Header Row
	var h_row := HBoxContainer.new()
	h_row.add_child(_create_cell("TEAM", 180, true))
	h_row.add_child(_create_cell("P", 50, true))
	h_row.add_child(_create_cell("W", 50, true))
	h_row.add_child(_create_cell("L", 50, true))
	h_row.add_child(_create_cell("PTS", 60, true))
	h_row.add_child(_create_cell("NRR", 90, true))
	table_vbox.add_child(h_row)

	# Populate rows sorted by points and NRR
	var team_keys: Array = TournamentManager.points_table.keys()
	team_keys.sort_custom(func(a, b):
		var pa: Dictionary = TournamentManager.points_table[a]
		var pb: Dictionary = TournamentManager.points_table[b]
		if pa["points"] == pb["points"]:
			return pa["nrr"] > pb["nrr"]
		return pa["points"] > pb["points"]
	)

	for t in team_keys:
		var p: Dictionary = TournamentManager.points_table[t]
		var row := HBoxContainer.new()
		row.add_child(_create_cell(p["name"], 180, false, Color(1, 0.9, 0.4) if t == TournamentManager.user_team_id else Color.WHITE))
		row.add_child(_create_cell(str(p["played"]), 50, false))
		row.add_child(_create_cell(str(p["won"]), 50, false))
		row.add_child(_create_cell(str(p["lost"]), 50, false))
		row.add_child(_create_cell(str(p["points"]), 60, false, Color(0.2, 0.9, 0.3)))
		row.add_child(_create_cell("%+.3f" % p["nrr"], 90, false))
		table_vbox.add_child(row)

	# Update Fixture
	var fix: Dictionary = TournamentManager.simulate_next_fixture_or_play()
	if fix.is_empty():
		fixture_label.text = "TOURNAMENT FINISHED!\nChampion: %s" % TournamentManager.champion_team
		play_btn.visible = false
		sim_btn.visible = false
	else:
		fixture_label.text = "%s vs %s\n(%s)" % [
			DataManager.get_team(fix["team_1"])["name"],
			DataManager.get_team(fix["team_2"])["name"],
			fix["stage"]
		]
		play_btn.visible = true
		sim_btn.visible = true

func _create_cell(txt: String, width: int, is_hdr: bool, col: Color = Color.WHITE) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.custom_minimum_size.x = width
	if is_hdr:
		lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
	else:
		lbl.add_theme_color_override("font_color", col)
	return lbl

func _on_play_fixture() -> void:
	var fix: Dictionary = TournamentManager.simulate_next_fixture_or_play()
	if not fix.is_empty():
		GameManager.setup_match(fix["team_1"], fix["team_2"], 5, "GREEN_TURF", "HARD", GameManager.GameMode.TOURNAMENT)
		get_tree().change_scene_to_file("res://scenes/match.tscn")

func _on_sim_fixture() -> void:
	var fix: Dictionary = TournamentManager.simulate_next_fixture_or_play()
	if not fix.is_empty():
		TournamentManager.simulate_ai_fixture(fix)

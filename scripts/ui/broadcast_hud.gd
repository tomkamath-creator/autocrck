extends Control
class_name BroadcastHUD

# BroadcastHUD: Complete Console-Grade Mobile Cricket TV Broadcast Interface

signal shot_button_pressed(shot_type: String)
signal camera_button_pressed()
signal pause_button_pressed()
signal skip_replay_pressed()
signal drs_requested()

# References to UI elements
var virtual_joystick: VirtualJoystick
var score_label: Label
var overs_label: Label
var crr_label: Label
var rrr_label: Label
var striker_label: Label
var non_striker_label: Label
var bowler_label: Label
var over_balls_container: HBoxContainer
var commentary_label: Label
var commentary_eq_rect: ColorRect
var timing_feedback_label: Label
var skip_replay_btn: Button
var drs_panel: PanelContainer
var drs_verdict_label: Label
var drs_hawkeye_label: Label

var loft_btn: Button
var drive_btn: Button
var defend_btn: Button
var cam_btn: Button
var pause_btn: Button

var eq_time: float = 0.0

func _ready() -> void:
	_build_ui_layout()
	_connect_events()
	update_hud()

func _process(delta: float) -> void:
	eq_time += delta * 12.0
	if commentary_eq_rect and commentary_eq_rect.visible:
		commentary_eq_rect.custom_minimum_size.x = 8.0 + abs(sin(eq_time)) * 14.0

func _connect_events() -> void:
	GameManager.score_updated.connect(_on_score_updated)
	GameManager.wicket_fallen.connect(_on_wicket_fallen)
	GameManager.milestone_reached.connect(_on_milestone)
	AudioManager.commentary_updated.connect(_on_commentary_received)

func _build_ui_layout() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	# 1. TOP COMMENTARY BANNER
	var top_bar := PanelContainer.new()
	top_bar.name = "TopBar"
	top_bar.anchor_left = 0.5
	top_bar.anchor_right = 0.5
	top_bar.offset_left = -300
	top_bar.offset_right = 300
	top_bar.offset_top = 16
	top_bar.offset_bottom = 58
	var style_top := StyleBoxFlat.new()
	style_top.bg_color = Color(0.08, 0.12, 0.18, 0.88)
	style_top.corner_radius_top_left = 20
	style_top.corner_radius_top_right = 20
	style_top.corner_radius_bottom_left = 20
	style_top.corner_radius_bottom_right = 20
	style_top.border_width_bottom = 2
	style_top.border_color = Color(0.2, 0.75, 1.0, 0.6)
	top_bar.add_theme_stylebox_override("panel", style_top)
	add_child(top_bar)

	var hbox_c := HBoxContainer.new()
	hbox_c.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_child(hbox_c)

	var live_pill := Label.new()
	live_pill.text = " LIVE "
	var pill_style := StyleBoxFlat.new()
	pill_style.bg_color = Color(0.85, 0.1, 0.15)
	pill_style.corner_radius_top_left = 4
	pill_style.corner_radius_top_right = 4
	pill_style.corner_radius_bottom_left = 4
	pill_style.corner_radius_bottom_right = 4
	live_pill.add_theme_stylebox_override("panel", pill_style)
	hbox_c.add_child(live_pill)

	var space := Control.new()
	space.custom_minimum_size.x = 10
	hbox_c.add_child(space)

	commentary_label = Label.new()
	commentary_label.text = "Welcome to CricStrike 3D! Bowler marking out run-up..."
	commentary_label.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	hbox_c.add_child(commentary_label)

	# 2. TOP RIGHT CONTROLS (CAM & PAUSE)
	var top_right := HBoxContainer.new()
	top_right.anchor_left = 1.0
	top_right.anchor_right = 1.0
	top_right.offset_left = -160
	top_right.offset_top = 16
	top_right.offset_right = -16
	top_right.offset_bottom = 56
	add_child(top_right)

	cam_btn = _create_action_pill("🎥 CAM")
	cam_btn.pressed.connect(func(): camera_button_pressed.emit())
	top_right.add_child(cam_btn)

	pause_btn = _create_action_pill("⏸ PAUSE")
	pause_btn.pressed.connect(func(): pause_button_pressed.emit())
	top_right.add_child(pause_btn)

	# 3. TIMING FEEDBACK POP-UP (CENTER SCREEN)
	timing_feedback_label = Label.new()
	timing_feedback_label.anchor_left = 0.5
	timing_feedback_label.anchor_right = 0.5
	timing_feedback_label.offset_left = -200
	timing_feedback_label.offset_right = 200
	timing_feedback_label.offset_top = 120
	timing_feedback_label.offset_bottom = 160
	timing_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timing_feedback_label.add_theme_font_size_override("font_size", 22)
	timing_feedback_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	timing_feedback_label.text = ""
	add_child(timing_feedback_label)

	# 4. SKIP REPLAY BUTTON
	skip_replay_btn = Button.new()
	skip_replay_btn.text = "⏩ SKIP REPLAY"
	skip_replay_btn.anchor_left = 1.0
	skip_replay_btn.anchor_top = 0.5
	skip_replay_btn.anchor_right = 1.0
	skip_replay_btn.anchor_bottom = 0.5
	skip_replay_btn.offset_left = -180
	skip_replay_btn.offset_right = -20
	skip_replay_btn.offset_top = -25
	skip_replay_btn.offset_bottom = 25
	var skip_style := StyleBoxFlat.new()
	skip_style.bg_color = Color(0.9, 0.45, 0.05, 0.9)
	skip_style.corner_radius_top_left = 12
	skip_style.corner_radius_top_right = 12
	skip_style.corner_radius_bottom_left = 12
	skip_style.corner_radius_bottom_right = 12
	skip_replay_btn.add_theme_stylebox_override("normal", skip_style)
	skip_replay_btn.visible = false
	skip_replay_btn.pressed.connect(func(): skip_replay_pressed.emit())
	add_child(skip_replay_btn)

	# 5. BOTTOM LEFT VIRTUAL JOYSTICK
	virtual_joystick = VirtualJoystick.new()
	virtual_joystick.anchor_top = 1.0
	virtual_joystick.anchor_bottom = 1.0
	virtual_joystick.offset_left = 32
	virtual_joystick.offset_top = -250
	virtual_joystick.offset_right = 192
	virtual_joystick.offset_bottom = -90
	add_child(virtual_joystick)

	# 6. BOTTOM RIGHT ACTION BUTTONS (LOFT, DRIVE, DEFEND)
	var action_vbox := VBoxContainer.new()
	action_vbox.anchor_left = 1.0
	action_vbox.anchor_top = 1.0
	action_vbox.anchor_right = 1.0
	action_vbox.anchor_bottom = 1.0
	action_vbox.offset_left = -170
	action_vbox.offset_top = -270
	action_vbox.offset_right = -24
	action_vbox.offset_bottom = -90
	action_vbox.add_theme_constant_override("separation", 10)
	add_child(action_vbox)

	loft_btn = _create_action_button("🔥 LOFT", Color(0.9, 0.2, 0.15))
	loft_btn.pressed.connect(func(): shot_button_pressed.emit("LOFT"))
	action_vbox.add_child(loft_btn)

	drive_btn = _create_action_button("⚡ DRIVE", Color(0.15, 0.65, 0.95))
	drive_btn.pressed.connect(func(): shot_button_pressed.emit("DRIVE"))
	action_vbox.add_child(drive_btn)

	defend_btn = _create_action_button("🛡 DEFEND", Color(0.3, 0.75, 0.35))
	defend_btn.pressed.connect(func(): shot_button_pressed.emit("DEFEND"))
	action_vbox.add_child(defend_btn)

	# 7. FULL-WIDTH BOTTOM TV BROADCAST SCORE BAR
	var bot_bar := PanelContainer.new()
	bot_bar.name = "BottomBar"
	bot_bar.anchor_top = 1.0
	bot_bar.anchor_right = 1.0
	bot_bar.anchor_bottom = 1.0
	bot_bar.offset_top = -78
	var style_bot := StyleBoxFlat.new()
	style_bot.bg_color = Color(0.06, 0.08, 0.12, 0.95)
	style_bot.border_width_top = 2
	style_bot.border_color = Color(0.95, 0.75, 0.12, 0.8)
	bot_bar.add_theme_stylebox_override("panel", style_bot)
	add_child(bot_bar)

	var hbox_b := HBoxContainer.new()
	hbox_b.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_b.add_theme_constant_override("separation", 18)
	bot_bar.add_child(hbox_b)

	# Team & Score
	score_label = Label.new()
	score_label.text = "IND  0 - 0"
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	hbox_b.add_child(score_label)

	# Overs
	overs_label = Label.new()
	overs_label.text = "OVERS 0.0 / 5"
	overs_label.add_theme_font_size_override("font_size", 16)
	hbox_b.add_child(overs_label)

	# CRR / RRR
	crr_label = Label.new()
	crr_label.text = "CRR: 0.00"
	crr_label.add_theme_font_size_override("font_size", 14)
	crr_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	hbox_b.add_child(crr_label)

	# Active Batsmen
	striker_label = Label.new()
	striker_label.text = "*R. Sharma 0 (0)"
	striker_label.add_theme_font_size_override("font_size", 15)
	hbox_b.add_child(striker_label)

	non_striker_label = Label.new()
	non_striker_label.text = "S. Gill 0 (0)"
	non_striker_label.add_theme_font_size_override("font_size", 15)
	non_striker_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	hbox_b.add_child(non_striker_label)

	# Bowler
	bowler_label = Label.new()
	bowler_label.text = "P. Cummins 0-0 (0.0)"
	bowler_label.add_theme_font_size_override("font_size", 15)
	bowler_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.4))
	hbox_b.add_child(bowler_label)

	# Over Ball Markers
	over_balls_container = HBoxContainer.new()
	over_balls_container.add_theme_constant_override("separation", 4)
	hbox_b.add_child(over_balls_container)

	# 8. DRS MODAL OVERLAY
	_build_drs_panel()

func _create_action_pill(title: String) -> Button:
	var btn := Button.new()
	btn.text = title
	btn.custom_minimum_size = Vector2(68, 36)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.2, 0.3, 0.85)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	btn.add_theme_stylebox_override("normal", style)
	return btn

func _create_action_button(title: String, col: Color) -> Button:
	var btn := Button.new()
	btn.text = title
	btn.custom_minimum_size = Vector2(135, 48)
	var style := StyleBoxFlat.new()
	style.bg_color = col
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 4
	btn.add_theme_stylebox_override("normal", style)
	return btn

func _build_drs_panel() -> void:
	drs_panel = PanelContainer.new()
	drs_panel.anchor_left = 0.5
	drs_panel.anchor_top = 0.5
	drs_panel.anchor_right = 0.5
	drs_panel.anchor_bottom = 0.5
	drs_panel.offset_left = -220
	drs_panel.offset_top = -140
	drs_panel.offset_right = 220
	drs_panel.offset_bottom = 140
	var style_drs := StyleBoxFlat.new()
	style_drs.bg_color = Color(0.08, 0.12, 0.18, 0.95)
	style_drs.border_width_left = 3
	style_drs.border_width_right = 3
	style_drs.border_width_top = 3
	style_drs.border_width_bottom = 3
	style_drs.border_color = Color(0.2, 0.8, 1.0)
	style_drs.corner_radius_top_left = 16
	style_drs.corner_radius_top_right = 16
	style_drs.corner_radius_bottom_left = 16
	style_drs.corner_radius_bottom_right = 16
	drs_panel.add_theme_stylebox_override("panel", style_drs)
	add_child(drs_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	drs_panel.add_child(vbox)

	var title := Label.new()
	title.text = "🎯 DECISION REVIEW SYSTEM (DRS)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
	vbox.add_child(title)

	drs_hawkeye_label = Label.new()
	drs_hawkeye_label.text = "Pitched: In Line\nImpact: In Line\nWickets: Hitting"
	drs_hawkeye_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(drs_hawkeye_label)

	drs_verdict_label = Label.new()
	drs_verdict_label.text = "VERDICT: OUT"
	drs_verdict_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drs_verdict_label.add_theme_font_size_override("font_size", 24)
	drs_verdict_label.add_theme_color_override("font_color", Color(0.9, 0.15, 0.15))
	vbox.add_child(drs_verdict_label)

	drs_panel.visible = false

func show_timing_feedback(timing: String, speed_kmh: float, sector: String) -> void:
	var color := Color(0.2, 0.9, 0.3)
	if timing == "PERFECT":
		color = Color(0.1, 1.0, 0.4)
	elif "EARLY" in timing or "LATE" in timing:
		color = Color(1.0, 0.85, 0.2)
	else:
		color = Color(0.9, 0.2, 0.2)
	
	timing_feedback_label.text = "%s!  %d KM/H  [%s]" % [timing, int(speed_kmh), sector]
	timing_feedback_label.add_theme_color_override("font_color", color)
	
	var tween := create_tween()
	timing_feedback_label.modulate.a = 1.0
	tween.tween_property(timing_feedback_label, "modulate:a", 0.0, 1.8)

func show_drs(hawkeye_data: Dictionary) -> void:
	drs_panel.visible = true
	drs_hawkeye_label.text = "Pitched: %s\nImpact: %s\nWickets: %s" % [
		hawkeye_data["pitched"],
		hawkeye_data["impact"],
		hawkeye_data["wickets"]
	]
	var is_out: bool = hawkeye_data["final_verdict"] == "OUT"
	drs_verdict_label.text = "VERDICT: %s" % hawkeye_data["final_verdict"]
	drs_verdict_label.add_theme_color_override("font_color", Color(0.9, 0.15, 0.15) if is_out else Color(0.15, 0.85, 0.25))

	var timer := get_tree().create_timer(3.5)
	timer.timeout.connect(func(): drs_panel.visible = false)

func update_hud() -> void:
	score_label.text = "%s  %d - %d" % [GameManager.batting_team_id, GameManager.runs_scored, GameManager.wickets_fallen]
	overs_label.text = "OVERS %s" % GameManager.get_overs_formatted()
	
	var total_balls: int = GameManager.legal_deliveries
	var crr: float = (float(GameManager.runs_scored) / max(float(total_balls) / 6.0, 0.166))
	crr_label.text = "CRR: %.2f" % crr

	if GameManager.batting_card.size() > GameManager.current_striker_idx:
		var s: Dictionary = GameManager.batting_card[GameManager.current_striker_idx]
		striker_label.text = "*%s %d (%d)" % [s["name"], s["runs"], s["balls"]]

	if GameManager.batting_card.size() > GameManager.current_non_striker_idx:
		var ns: Dictionary = GameManager.batting_card[GameManager.current_non_striker_idx]
		non_striker_label.text = "%s %d (%d)" % [ns["name"], ns["runs"], ns["balls"]]

	if GameManager.bowling_card.size() > GameManager.current_bowler_idx:
		var b: Dictionary = GameManager.bowling_card[GameManager.current_bowler_idx]
		bowler_label.text = "%s %d-%d (%.1f)" % [b["name"], b["wickets"], b["runs_conceded"], b["overs"]]

	# Render over ball markers
	for child in over_balls_container.get_children():
		child.queue_free()

	for b_marker in GameManager.current_over_balls:
		var pill := Label.new()
		pill.text = " " + b_marker + " "
		var style := StyleBoxFlat.new()
		if b_marker == "4":
			style.bg_color = Color(0.1, 0.4, 0.8)
		elif b_marker == "6":
			style.bg_color = Color(0.8, 0.15, 0.8)
		elif b_marker == "W":
			style.bg_color = Color(0.85, 0.1, 0.1)
		else:
			style.bg_color = Color(0.2, 0.25, 0.3)
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		pill.add_theme_stylebox_override("panel", style)
		over_balls_container.add_child(pill)

func _on_score_updated(_r: int, _w: int, _ov: String) -> void:
	update_hud()

func _on_wicket_fallen(dismissal: String, player: String) -> void:
	timing_feedback_label.text = "WICKET! %s (%s)" % [player, dismissal]
	timing_feedback_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	var tween := create_tween()
	timing_feedback_label.modulate.a = 1.0
	tween.tween_property(timing_feedback_label, "modulate:a", 0.0, 2.5)

func _on_milestone(type: String, player: String) -> void:
	timing_feedback_label.text = "🌟 %s FOR %s! 🌟" % [type, player.to_upper()]
	timing_feedback_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	var tween := create_tween()
	timing_feedback_label.modulate.a = 1.0
	tween.tween_property(timing_feedback_label, "modulate:a", 0.0, 3.0)

func _on_commentary_received(text: String, _tag: String) -> void:
	commentary_label.text = text

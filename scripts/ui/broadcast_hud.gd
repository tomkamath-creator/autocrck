# scripts/ui/broadcast_hud.gd
# Clean Mobile Broadcast HUD, TV Score Ribbon, Commentary Ticker & Over Transitions
class_name BroadcastHUD
extends CanvasLayer

signal cam_button_pressed()
signal pause_button_pressed()
signal shot_button_pressed(shot_type_str: String)

# UI Elements
@onready var bottom_ribbon: Panel = $BottomRibbon
@onready var label_team_score: Label = $BottomRibbon/TeamScoreLabel
@onready var label_overs: Label = $BottomRibbon/OversLabel
@onready var label_crr_rrr: Label = $BottomRibbon/RatesLabel
@onready var label_strikers: Label = $BottomRibbon/StrikersLabel
@onready var label_bowler: Label = $BottomRibbon/BowlerLabel
@onready var over_balls_container: HBoxContainer = $BottomRibbon/OverBallsContainer

@onready var top_commentary_bar: Panel = $TopCommentaryBar
@onready var label_commentator: Label = $TopCommentaryBar/CommentatorTag
@onready var label_commentary_text: Label = $TopCommentaryBar/CommentaryText

@onready var btn_cam: Button = $TopControls/BtnCam
@onready var btn_pause: Button = $TopControls/BtnPause

# Mobile On-Screen Controls
@onready var joystick: VirtualJoystick = $Controls/VirtualJoystick
@onready var btn_loft: TouchActionButton = $Controls/BtnLoft
@onready var btn_drive: TouchActionButton = $Controls/BtnDrive
@onready var btn_defend: TouchActionButton = $Controls/BtnDefend

# Transition Graphics
@onready var bowler_card: Panel = $BowlerCardLowerThird
@onready var wagon_wheel_popup: Panel = $WagonWheelPopup

func _ready() -> void:
	_connect_events()
	_init_hud_styles()

func _connect_events() -> void:
	if btn_cam: btn_cam.pressed.connect(func(): emit_signal("cam_button_pressed"))
	if btn_pause: btn_pause.pressed.connect(func(): emit_signal("pause_button_pressed"))
	
	if btn_loft: btn_loft.action_triggered.connect(func(act): emit_signal("shot_button_pressed", "LOFT"))
	if btn_drive: btn_drive.action_triggered.connect(func(act): emit_signal("shot_button_pressed", "DRIVE"))
	if btn_defend: btn_defend.action_triggered.connect(func(act): emit_signal("shot_button_pressed", "DEFEND"))
	
	CommentaryManager.commentary_updated.connect(_on_commentary_updated)
	GameManager.score_updated.connect(_on_score_updated)
	GameManager.ball_recorded.connect(_on_ball_recorded)
	GameManager.over_completed.connect(_on_over_completed)

func _init_hud_styles() -> void:
	if bowler_card: bowler_card.visible = false
	if wagon_wheel_popup: wagon_wheel_popup.visible = false

func _on_score_updated(runs: int, wickets: int, overs: String, target: int, crr: float, rrr: float) -> void:
	if label_team_score:
		label_team_score.text = GameManager.batting_team.to_upper() + "  " + str(runs) + "/" + str(wickets)
	if label_overs:
		label_overs.text = "OVERS " + overs + " (" + str(GameManager.selected_overs) + ")"
	if label_crr_rrr:
		var rates_str = "CRR: " + str(snapped(crr, 0.01))
		if target > 0:
			rates_str += " | REQ: " + str(target - runs) + " OFF " + str((GameManager.selected_overs * 6) - GameManager.legal_balls) + " (RRR: " + str(snapped(rrr, 0.01)) + ")"
		label_crr_rrr.text = rates_str
	
	if label_strikers:
		label_strikers.text = "*" + GameManager.striker_name + " " + str(GameManager.striker_runs) + "(" + str(GameManager.striker_balls) + ")  |  " + GameManager.non_striker_name + " " + str(GameManager.non_striker_runs) + "(" + str(GameManager.non_striker_balls) + ")"
	
	if label_bowler:
		var b_overs = str(GameManager.bowler_overs_balls / 6) + "." + str(GameManager.bowler_overs_balls % 6)
		label_bowler.text = GameManager.current_bowler_name + "  " + b_overs + "-" + str(GameManager.bowler_runs_conceded) + "-" + str(GameManager.bowler_wickets_taken)

func _on_ball_recorded(ball_str: String) -> void:
	if not over_balls_container:
		return
	var ball_pill = Label.new()
	ball_pill.text = " " + ball_str + " "
	ball_pill.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Color badge based on outcome
	if ball_str == "6":
		ball_pill.modulate = Color(1.0, 0.85, 0.0) # Gold
	elif ball_str == "4":
		ball_pill.modulate = Color(0.2, 0.9, 0.4) # Bright green
	elif ball_str == "W":
		ball_pill.modulate = Color(1.0, 0.2, 0.2) # Crimson Red
	else:
		ball_pill.modulate = Color(0.85, 0.9, 0.95)
	
	over_balls_container.add_child(ball_pill)

func _on_commentary_updated(speaker: String, text: String, excitement: int) -> void:
	if label_commentator: label_commentator.text = speaker.to_upper()
	if label_commentary_text: label_commentary_text.text = text

func _on_over_completed(bowler_name: String, runs_conceded: int) -> void:
	# Clear over ball markers
	if over_balls_container:
		for c in over_balls_container.get_children():
			c.queue_free()
	
	# Bowler Card Lower-Third Animation
	if bowler_card:
		bowler_card.visible = true
		var t = create_tween()
		t.tween_property(bowler_card, "position:y", 560.0, 0.35).set_trans(Tween.TRANS_CUBIC)
		t.tween_interval(2.5)
		t.tween_property(bowler_card, "position:y", 730.0, 0.35).set_trans(Tween.TRANS_CUBIC)
		t.tween_callback(func(): bowler_card.visible = false)

func show_wagon_wheel_milestone(batsman_name: String, runs: int) -> void:
	if not wagon_wheel_popup:
		return
	wagon_wheel_popup.visible = true
	var lbl = wagon_wheel_popup.get_node_or_null("MilestoneLabel")
	if lbl and lbl is Label:
		lbl.text = batsman_name.to_upper() + " - " + str(runs) + " RUNS MILESTONE!"
	
	var t = create_tween()
	t.tween_interval(3.0)
	t.tween_callback(func(): wagon_wheel_popup.visible = false)

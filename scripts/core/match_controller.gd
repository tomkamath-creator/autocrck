# scripts/core/match_controller.gd
# Core 3D Match Orchestrator for CricStrike 3D
# Assembles 3D stadium, players, cricket ball, cameras, broadcast HUD, replay & DRS.
class_name MatchController
extends Node3D

@onready var stadium_root: Node3D = $StadiumContainer
@onready var camera: BroadcastCamera = $BroadcastCamera
@onready var hud: BroadcastHUD = $BroadcastHUD
@onready var drs_overlay: DRSOverlay = $DRSOverlay
@onready var replay_overlay: Control = $ReplayOverlay
@onready var btn_skip_replay: Button = $ReplayOverlay/BtnSkipReplay

var ball: CricketBall
var batsman_striker: BatsmanController
var batsman_non_striker: CricketPlayer
var bowler: BowlerController
var wicketkeeper: FielderController
var fielders: Array[FielderController] = []
var umpire: CricketPlayer

var runs_on_current_ball: int = 0
var is_ball_in_play: bool = false

func _ready() -> void:
	_build_scene_environment()
	_spawn_cricket_actors()
	_connect_match_signals()
	_start_match()

func _build_scene_environment() -> void:
	# Add WorldEnvironment with daytime stadium lighting
	var env = WorldEnvironment.new()
	var env_res = Environment.new()
	env_res.background_mode = Environment.BG_COLOR
	env_res.background_color = Color(0.45, 0.68, 0.92) # Daylight blue sky
	env_res.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env_res.ambient_light_color = Color(0.85, 0.9, 0.95)
	env_res.ambient_light_energy = 1.0
	env.environment = env_res
	add_child(env)
	
	# Directional Sunlight
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_color = Color(1.0, 0.98, 0.92)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)
	
	# Build 3D Stadium
	var stadium = StadiumBuilder.build_stadium()
	stadium_root.add_child(stadium)

func _spawn_cricket_actors() -> void:
	# 1. Cricket Ball
	ball = CricketBall.new()
	ball.name = "CricketBall"
	add_child(ball)
	
	# 2. Striker Batsman
	batsman_striker = BatsmanController.new()
	batsman_striker.name = "Striker"
	batsman_striker.player_name = GameManager.striker_name
	batsman_striker.team_name = GameManager.batting_team
	batsman_striker.role = "Batsman"
	add_child(batsman_striker)
	batsman_striker.setup_batsman(ball)
	
	# 3. Non-Striker Batsman
	batsman_non_striker = CricketPlayer.new()
	batsman_non_striker.name = "NonStriker"
	batsman_non_striker.player_name = GameManager.non_striker_name
	batsman_non_striker.team_name = GameManager.batting_team
	batsman_non_striker.role = "Batsman"
	add_child(batsman_non_striker)
	batsman_non_striker.global_position = Vector3(-0.95, 0, -8.84)
	batsman_non_striker.safe_look_at(Vector3(-0.95, 0, 10.0))
	
	# 4. Bowler
	bowler = BowlerController.new()
	bowler.name = "Bowler"
	bowler.player_name = GameManager.current_bowler_name
	bowler.team_name = GameManager.bowling_team
	add_child(bowler)
	bowler.setup_bowler(ball, BowlerController.BowlingStyle.EXPRESS_FAST)
	
	# 5. Wicketkeeper
	wicketkeeper = FielderController.new()
	wicketkeeper.name = "Wicketkeeper"
	wicketkeeper.player_name = "Keeper"
	wicketkeeper.team_name = GameManager.bowling_team
	add_child(wicketkeeper)
	wicketkeeper.setup_fielder(ball, Vector3(0, 0, 13.8), true)
	
	# 6. 9 Fielders based on BALANCED Preset
	var field_pos = FielderController.get_field_positions(FielderController.FieldPreset.BALANCED)
	fielders.clear()
	for i in range(field_pos.size()):
		var f = FielderController.new()
		f.name = "Fielder_" + str(i + 1)
		f.player_name = "Fielder " + str(i + 1)
		f.team_name = GameManager.bowling_team
		add_child(f)
		f.setup_fielder(ball, field_pos[i], false)
		fielders.append(f)
	
	# 7. Umpire
	umpire = CricketPlayer.new()
	umpire.name = "Umpire"
	umpire.role = "Umpire"
	umpire.player_name = "Umpire"
	add_child(umpire)
	umpire.global_position = Vector3(0, 0, -12.4)
	umpire.safe_look_at(Vector3(0, 0, 10.0))
	
	# Setup Camera Targets
	camera.setup_targets(batsman_striker, bowler, ball)

func _connect_match_signals() -> void:
	# HUD Touch Controls
	hud.cam_button_pressed.connect(func(): camera.cycle_camera_mode())
	hud.pause_button_pressed.connect(_on_pause_pressed)
	hud.shot_button_pressed.connect(_on_shot_button_pressed)
	
	if hud.joystick:
		hud.joystick.joystick_vector_changed.connect(func(v): batsman_striker.set_joystick_input(v))
	
	# Ball Signals
	ball.ball_pitched.connect(_on_ball_pitched)
	ball.ball_hit_bat.connect(_on_ball_hit_bat)
	ball.ball_hit_boundary.connect(_on_boundary_hit)
	ball.ball_dead.connect(_on_ball_dead)
	
	# Fielder Signals
	wicketkeeper.ball_fielded.connect(_on_ball_fielded)
	for f in fielders:
		f.ball_fielded.connect(_on_ball_fielded)
	
	# Bowler Signals
	bowler.delivery_released.connect(_on_delivery_released)
	
	# Game Manager Events
	GameManager.replay_requested.connect(_on_replay_requested)
	
	# Replay Overlay Skip Button
	if btn_skip_replay:
		btn_skip_replay.pressed.connect(func(): camera.skip_replay())
	
	camera.replay_started.connect(func(ev): replay_overlay.visible = true)
	camera.replay_finished.connect(func():
		replay_overlay.visible = false
		_reset_delivery_positions()
	)

func _start_match() -> void:
	runs_on_current_ball = 0
	is_ball_in_play = false
	if replay_overlay: replay_overlay.visible = false

func _on_shot_button_pressed(shot_str: String) -> void:
	match shot_str:
		"LOFT":
			batsman_striker.trigger_shot_action(BatsmanController.ShotType.LOFT)
		"DRIVE":
			batsman_striker.trigger_shot_action(BatsmanController.ShotType.DRIVE)
		"DEFEND":
			batsman_striker.trigger_shot_action(BatsmanController.ShotType.DEFEND)

func _on_delivery_released(style: String, speed: float) -> void:
	is_ball_in_play = true
	runs_on_current_ball = 0
	batsman_striker.setup_batsman(ball)

func _on_ball_pitched(pos: Vector3, vel: Vector3) -> void:
	pass

func _on_ball_hit_bat(impact_pos: Vector3, quality: String) -> void:
	camera.add_trauma(0.3)

func _on_boundary_hit(runs: int) -> void:
	is_ball_in_play = false
	runs_on_current_ball = runs
	umpire.play_animation("umpire_six" if runs == 6 else "umpire_four", 1.2, false)
	GameManager.record_delivery(runs, false)

func _on_ball_fielded(fielder_name: String, is_catch: bool) -> void:
	if not is_ball_in_play:
		return
	is_ball_in_play = false
	
	if is_catch:
		# OUT CAUGHT!
		umpire.play_animation("umpire_out", 1.0, false)
		GameManager.record_delivery(0, true, "caught")
	else:
		# Fielded cleanly, estimate runs taken (0, 1, or 2 based on distance from stumps)
		var runs = 0
		if ball.has_hit_bat:
			var dist = ball.global_position.distance_to(Vector3(0, 0, 10.0))
			runs = 1 if dist > 18.0 else 0
			if dist > 35.0: runs = 2
		GameManager.record_delivery(runs, false)
		
		# If no replay requested, tee up next ball after 2.2s
		get_tree().create_timer(2.2).timeout.connect(_reset_delivery_positions)

func _on_ball_dead(reason: String) -> void:
	if is_ball_in_play:
		is_ball_in_play = false
		GameManager.record_delivery(0, false)
		get_tree().create_timer(2.2).timeout.connect(_reset_delivery_positions)

func _on_replay_requested(event_type: String) -> void:
	camera.trigger_slowmo_replay(event_type)

func _reset_delivery_positions() -> void:
	ball.state = CricketBall.BallState.IN_HAND
	ball.visible = false
	
	batsman_striker.setup_batsman(ball)
	wicketkeeper.reset_position()
	for f in fielders:
		f.reset_position()
	
	bowler.queue_next_delivery()

func _on_pause_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

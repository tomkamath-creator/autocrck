extends Node3D
class_name MatchController

# MatchController: Master Scene Orchestrator for 3D Cricket Matches

@onready var camera: Camera3D = $Camera3D
@onready var hud: BroadcastHUD = $BroadcastHUD

var stadium: StadiumModel
var stumps_striker: StumpsModel
var stumps_non_striker: StumpsModel
var ball: BallPhysics

var striker_batsman: PlayerCharacter
var non_striker_batsman: PlayerCharacter
var active_bowler: PlayerCharacter
var wicketkeeper: PlayerCharacter
var umpire: PlayerCharacter
var fielders: Array[PlayerCharacter] = []

var batting_ctrl: BattingController
var bowling_ctrl: BowlingController
var fielding_ctrl: FieldingController
var replay_sys: ReplaySystem
var drs_sys: DRSSystem

func _ready() -> void:
	_setup_3d_environment()
	_setup_entities()
	_setup_gameplay_controllers()
	_connect_hud_signals()

	# Start bowling sequence
	bowling_ctrl.start_ai_delivery()

func _setup_3d_environment() -> void:
	# Directional Sunlight
	var sun := DirectionalLight3D.new()
	sun.position = Vector3(10, 45, 20)
	sun.rotation = Vector3(deg_to_rad(-55.0), deg_to_rad(35.0), 0)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	add_child(sun)

	# World Environment
	var env := WorldEnvironment.new()
	var env_res := Environment.new()
	env_res.background_mode = Environment.BG_COLOR
	env_res.background_color = Color(0.45, 0.68, 0.92) # Daylight sky
	env_res.ambient_light_color = Color(0.75, 0.85, 0.95)
	env_res.ambient_light_energy = 0.6
	env.environment = env_res
	add_child(env)

	# 3D Stadium
	stadium = StadiumModel.new()
	add_child(stadium)

	# Stumps
	stumps_striker = StumpsModel.new()
	stumps_striker.position = Vector3(0, 0, 10.06)
	add_child(stumps_striker)

	stumps_non_striker = StumpsModel.new()
	stumps_non_striker.position = Vector3(0, 0, -10.06)
	add_child(stumps_non_striker)

	# Cricket Ball
	ball = BallPhysics.new()
	add_child(ball)

func _setup_entities() -> void:
	# Striker Batsman
	striker_batsman = PlayerCharacter.new()
	striker_batsman.role = PlayerCharacter.PlayerRole.BATSMAN
	striker_batsman.team_id = GameManager.batting_team_id
	striker_batsman.position = Vector3(0.18, 0.0, 9.05)
	add_child(striker_batsman)
	striker_batsman.look_at_flat(Vector3(0, 0, -10.0))
	striker_batsman.play_animation("stance")

	# Non-Striker Batsman
	non_striker_batsman = PlayerCharacter.new()
	non_striker_batsman.role = PlayerCharacter.PlayerRole.BATSMAN
	non_striker_batsman.team_id = GameManager.batting_team_id
	non_striker_batsman.position = Vector3(-0.9, 0.0, -9.05)
	add_child(non_striker_batsman)
	non_striker_batsman.look_at_flat(Vector3(0, 0, 10.0))
	non_striker_batsman.play_animation("stance")

	# Bowler
	active_bowler = PlayerCharacter.new()
	active_bowler.role = PlayerCharacter.PlayerRole.BOWLER
	active_bowler.team_id = GameManager.bowling_team_id
	active_bowler.position = Vector3(0.35, 0.0, -18.0)
	add_child(active_bowler)

	# Wicketkeeper
	wicketkeeper = PlayerCharacter.new()
	wicketkeeper.role = PlayerCharacter.PlayerRole.WICKETKEEPER
	wicketkeeper.team_id = GameManager.bowling_team_id
	wicketkeeper.position = Vector3(0.0, 0.0, 13.5)
	add_child(wicketkeeper)

	# Umpire
	umpire = PlayerCharacter.new()
	umpire.role = PlayerCharacter.PlayerRole.UMPIRE
	umpire.position = Vector3(0.0, 0.0, -10.8)
	add_child(umpire)
	umpire.look_at_flat(Vector3(0, 0, 10.0))

	# 9 Outfielders
	for i in range(9):
		var f := PlayerCharacter.new()
		f.role = PlayerCharacter.PlayerRole.FIELDER
		f.team_id = GameManager.bowling_team_id
		add_child(f)
		fielders.append(f)

func _setup_gameplay_controllers() -> void:
	# Batting Controller
	batting_ctrl = BattingController.new()
	add_child(batting_ctrl)
	batting_ctrl.init(striker_batsman, ball)
	batting_ctrl.shot_executed.connect(_on_shot_executed)

	# Bowling Controller
	bowling_ctrl = BowlingController.new()
	add_child(bowling_ctrl)
	bowling_ctrl.init(active_bowler, ball)

	# Fielding Controller
	fielding_ctrl = FieldingController.new()
	add_child(fielding_ctrl)
	fielding_ctrl.init(fielders, wicketkeeper, ball)

	# Replay System
	replay_sys = ReplaySystem.new()
	add_child(replay_sys)
	replay_sys.init(camera, ball, striker_batsman, active_bowler)
	replay_sys.replay_started.connect(func(): hud.skip_replay_btn.visible = true)
	replay_sys.replay_finished.connect(func(): hud.skip_replay_btn.visible = false)

	# DRS System
	drs_sys = DRSSystem.new()
	add_child(drs_sys)
	drs_sys.init(ball)

	# Connect Ball to Stumps shattering
	ball.ball_hit_stumps.connect(func():
		stumps_striker.shatter_stumps()
		replay_sys.trigger_slow_motion_replay()
	)
	ball.ball_boundary_scored.connect(func(runs):
		if runs == 4:
			umpire.play_animation("umpire_four")
		elif runs == 6:
			umpire.play_animation("umpire_six")
		replay_sys.trigger_slow_motion_replay()
	)

func _connect_hud_signals() -> void:
	hud.shot_button_pressed.connect(_on_hud_shot_pressed)
	hud.camera_button_pressed.connect(_on_hud_camera_pressed)
	hud.skip_replay_pressed.connect(func(): replay_sys.skip_replay())
	hud.pause_button_pressed.connect(_on_hud_pause_pressed)

func _on_hud_shot_pressed(shot_type: String) -> void:
	var joy_dir: Vector2 = hud.virtual_joystick.joystick_vector
	batting_ctrl.execute_shot(shot_type, joy_dir)

func _on_shot_executed(timing: String, exit_speed_kmh: float, sector: String) -> void:
	hud.show_timing_feedback(timing, exit_speed_kmh, sector)

func _on_hud_camera_pressed() -> void:
	GameManager.cycle_camera()
	replay_sys.apply_camera_mode(GameManager.current_camera_mode)

func _on_hud_pause_pressed() -> void:
	get_tree().paused = not get_tree().paused

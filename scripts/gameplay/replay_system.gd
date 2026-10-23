extends Node
class_name ReplaySystem

# ReplaySystem: 3-Second Multi-Angle Slow-Motion TV Replay & 6 Broadcast Camera Rigs

signal replay_started()
signal replay_finished()

var camera: Camera3D
var ball: BallPhysics
var batsman: PlayerCharacter
var bowler: PlayerCharacter

var is_replaying: bool = false
var replay_timer: float = 0.0
var replay_duration: float = 3.2
var replay_angle_idx: int = 0

# Broadcast camera mode positions (relative to origin)
const CAMERA_PRESETS: Dictionary = {
	"BEHIND_BATSMAN": {"pos": Vector3(0.0, 1.85, 12.6), "target": Vector3(0.0, 1.1, -10.0)},
	"BOWLER_POV": {"pos": Vector3(0.35, 2.3, -16.0), "target": Vector3(0.0, 1.0, 9.05)},
	"BROADCAST_SIDE": {"pos": Vector3(36.0, 14.0, 0.0), "target": Vector3(0.0, 1.0, 0.0)},
	"BALL_TRACKING": {"pos": Vector3(0.0, 4.0, 6.0), "target": Vector3.ZERO},
	"BATSMAN_HELMET_POV": {"pos": Vector3(0.0, 1.74, 9.1), "target": Vector3(0.0, 1.2, -10.0)},
	"UMPIRE_POV": {"pos": Vector3(0.0, 1.84, -10.6), "target": Vector3(0.0, 1.0, 9.05)}
}

# 3 Replay Angles
const REPLAY_ANGLES: Array[Dictionary] = [
	{"pos": Vector3(0.0, 1.1, -12.5), "target": Vector3(0.0, 0.8, 9.05), "fov": 45.0}, # Pitch Delivery Cam
	{"pos": Vector3(-2.8, 0.9, 8.2), "target": Vector3(0.0, 0.9, 9.05), "fov": 35.0},  # Crease Impact Cam
	{"pos": Vector3(20.0, 16.0, 24.0), "target": Vector3(0.0, 0.5, 0.0), "fov": 55.0}  # Reverse Sky Cam
]

func init(cam: Camera3D, ball_inst: BallPhysics, bat_char: PlayerCharacter, bowl_char: PlayerCharacter) -> void:
	camera = cam
	ball = ball_inst
	batsman = bat_char
	bowler = bowl_char
	apply_camera_mode(GameManager.current_camera_mode)

func _process(delta: float) -> void:
	if is_replaying:
		_process_replay(delta)
	else:
		_update_live_camera(delta)

func apply_camera_mode(mode: GameManager.CameraMode) -> void:
	var mode_key: String = GameManager.CameraMode.keys()[mode]
	if CAMERA_PRESETS.has(mode_key) and camera:
		var p: Dictionary = CAMERA_PRESETS[mode_key]
		camera.global_position = p["pos"]
		camera.look_at(p["target"], Vector3.UP)
		camera.fov = 60.0

func _update_live_camera(_delta: float) -> void:
	if not camera or not ball:
		return
	
	if GameManager.current_camera_mode == GameManager.CameraMode.BALL_TRACKING:
		# Smooth ball tracking camera
		var target_cam_pos: Vector3 = ball.global_position + Vector3(0.0, 3.5, 5.5)
		camera.global_position = camera.global_position.lerp(target_cam_pos, 0.12)
		camera.look_at(ball.global_position, Vector3.UP)
	elif GameManager.current_camera_mode == GameManager.CameraMode.BOWLER_POV and bowler:
		var bowler_head: Vector3 = bowler.global_position + Vector3(0.2, 2.2, -1.8)
		camera.global_position = bowler_head
		camera.look_at(Vector3(0, 1.0, 9.05), Vector3.UP)

func trigger_slow_motion_replay() -> void:
	if is_replaying:
		return
	is_replaying = true
	replay_timer = 0.0
	replay_angle_idx = 0
	Engine.time_scale = 0.42 # Cinematic slow motion
	replay_started.emit()
	_apply_replay_camera(0)

func _process_replay(delta: float) -> void:
	replay_timer += delta / Engine.time_scale
	
	# Transition through the 3 replay angles
	var angle_duration: float = replay_duration / 3.0
	var current_idx: int = clampi(int(replay_timer / angle_duration), 0, 2)
	
	if current_idx != replay_angle_idx:
		replay_angle_idx = current_idx
		_apply_replay_camera(replay_angle_idx)
	
	# Smoothly track ball during replay
	if ball and replay_angle_idx == 2:
		camera.look_at(ball.global_position, Vector3.UP)
	
	if replay_timer >= replay_duration:
		skip_replay()

func _apply_replay_camera(idx: int) -> void:
	if idx < REPLAY_ANGLES.size() and camera:
		var cfg: Dictionary = REPLAY_ANGLES[idx]
		camera.global_position = cfg["pos"]
		camera.look_at(cfg["target"], Vector3.UP)
		camera.fov = cfg["fov"]

func skip_replay() -> void:
	if not is_replaying:
		return
	is_replaying = false
	Engine.time_scale = 1.0
	apply_camera_mode(GameManager.current_camera_mode)
	replay_finished.emit()

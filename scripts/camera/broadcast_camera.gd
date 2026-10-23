# scripts/camera/broadcast_camera.gd
# Broadcast Cinematics, 6 TV Camera Angles & 3-Second Slow-Mo TV Replay System
class_name BroadcastCamera
extends Camera3D

signal replay_started(event_name: String)
signal replay_finished()

enum CameraMode {
	BEHIND_BATSMAN,
	BOWLER_POV,
	BROADCAST_SIDE,
	BALL_TRACKING,
	BATSMAN_HELMET_POV,
	UMPIRE_POV
}

var current_mode: CameraMode = CameraMode.BEHIND_BATSMAN
var target_pos: Vector3 = Vector3.ZERO
var target_look: Vector3 = Vector3.ZERO
var smooth_speed: float = 7.0

# Target References
var batsman_node: Node3D
var bowler_node: Node3D
var ball_node: Node3D

# Slow-Motion Replay Subsystem
var is_replaying: bool = false
var replay_time: float = 0.0
const REPLAY_TOTAL_DURATION: float = 3.2
var replay_angle_index: int = 0 # 0: Pitch Delivery Cam, 1: Crease Impact Cam, 2: Reverse Sky Cam

# Camera Shake
var trauma: float = 0.0

func _ready() -> void:
	fov = 58.0

func setup_targets(batsman: Node3D, bowler: Node3D, ball: Node3D) -> void:
	batsman_node = batsman
	bowler_node = bowler
	ball_node = ball
	set_camera_mode(CameraMode.BEHIND_BATSMAN)

func set_camera_mode(mode: CameraMode) -> void:
	current_mode = mode
	if is_replaying:
		return
	_update_target_transform()
	global_position = target_pos
	look_at(target_look, Vector3.UP)

func cycle_camera_mode() -> void:
	var next_mode = (int(current_mode) + 1) % CameraMode.size()
	set_camera_mode(next_mode as CameraMode)

func trigger_slowmo_replay(event_name: String) -> void:
	is_replaying = true
	replay_time = 0.0
	replay_angle_index = 0
	emit_signal("replay_started", event_name)

func skip_replay() -> void:
	if not is_replaying:
		return
	is_replaying = false
	emit_signal("replay_finished")
	set_camera_mode(current_mode)

func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)

func _physics_process(delta: float) -> void:
	if is_replaying:
		_process_replay(delta)
	else:
		_process_live_camera(delta)
	
	# Apply camera trauma shake
	if trauma > 0.01:
		trauma = maxf(0.0, trauma - delta * 1.8)
		var shake_offset = Vector3(
			(randf() * 2.0 - 1.0) * trauma * 0.12,
			(randf() * 2.0 - 1.0) * trauma * 0.12,
			(randf() * 2.0 - 1.0) * trauma * 0.08
		)
		global_position += shake_offset

func _process_live_camera(delta: float) -> void:
	_update_target_transform()
	global_position = global_position.lerp(target_pos, clampf(delta * smooth_speed, 0.0, 1.0))
	
	# Safe target look-at
	if global_position.distance_squared_to(target_look) > 0.1:
		var current_quat = global_transform.basis.get_rotation_quaternion()
		var target_trans = global_transform.looking_at(target_look, Vector3.UP)
		var target_quat = target_trans.basis.get_rotation_quaternion()
		global_transform.basis = Basis(current_quat.slerp(target_quat, clampf(delta * smooth_speed, 0.0, 1.0)))

func _process_replay(delta: float) -> void:
	replay_time += delta
	
	# Cycle across 3 dynamic slow-mo camera angles:
	# 0.0s - 1.0s: Pitch Delivery Cam (low angle looking down the pitch)
	# 1.0s - 2.1s: Crease Impact Cam (tight close-up of bat-ball contact)
	# 2.1s - 3.2s: Reverse Sky Cam (wide stadium aerial tracking)
	if replay_time < 1.0:
		replay_angle_index = 0
		target_pos = Vector3(0.8, 0.45, -11.5) # Low pitch delivery angle
		target_look = Vector3(0.0, 0.8, 9.0)
	elif replay_time < 2.1:
		replay_angle_index = 1
		target_pos = Vector3(2.4, 0.95, 9.6) # Tight crease impact close-up
		target_look = Vector3(0.0, 0.9, 9.05)
	elif replay_time < REPLAY_TOTAL_DURATION:
		replay_angle_index = 2
		target_pos = Vector3(-25.0, 18.0, 25.0) # Wide reverse sky cam
		if ball_node:
			target_look = ball_node.global_position
		else:
			target_look = Vector3(0, 1.0, 0)
	else:
		skip_replay()
		return
	
	global_position = global_position.lerp(target_pos, delta * 5.0)
	if global_position.distance_squared_to(target_look) > 0.1:
		look_at(target_look, Vector3.UP)

func _update_target_transform() -> void:
	match current_mode:
		CameraMode.BEHIND_BATSMAN:
			# Standard live batting broadcast view from behind striker
			target_pos = Vector3(0.0, 2.75, 14.8)
			target_look = Vector3(0.0, 1.15, -4.0)
		CameraMode.BOWLER_POV:
			# Behind bowler running in from non-striker end
			if bowler_node:
				target_pos = bowler_node.global_position + Vector3(0.0, 2.8, -4.5)
			else:
				target_pos = Vector3(0.0, 3.2, -18.0)
			target_look = Vector3(0.0, 1.0, 9.05)
		CameraMode.BROADCAST_SIDE:
			# Classic TV broadcast side-on grandstand view
			target_pos = Vector3(32.0, 12.0, 0.0)
			target_look = Vector3(0.0, 0.8, 0.0)
		CameraMode.BALL_TRACKING:
			# Smooth cinematic ball follow
			if ball_node:
				target_pos = ball_node.global_position + Vector3(4.0, 3.5, 6.0)
				target_look = ball_node.global_position
			else:
				target_pos = Vector3(0.0, 2.75, 14.8)
				target_look = Vector3(0.0, 1.0, 0.0)
		CameraMode.BATSMAN_HELMET_POV:
			# First-person immersive helmet visor cam
			if batsman_node:
				target_pos = batsman_node.global_position + Vector3(0.0, 1.74, -0.05)
			else:
				target_pos = Vector3(0.25, 1.74, 9.0)
			target_look = Vector3(0.0, 1.15, -12.0)
		CameraMode.UMPIRE_POV:
			# Behind bowler's wickets looking at batsman
			target_pos = Vector3(0.0, 1.85, -12.2)
			target_look = Vector3(0.0, 1.1, 9.05)

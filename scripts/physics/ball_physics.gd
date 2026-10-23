extends Node3D
class_name BallPhysics

# BallPhysics: Cricket Ball Aerodynamics, Pitch Surface Restitution, Swing & Magnus Effects

signal ball_bounced(position: Vector3, normal: Vector3)
signal ball_hit_bat(impact_pos: Vector3, exit_speed_kmh: float)
signal ball_hit_stumps()
signal ball_caught_by_keeper()
signal ball_boundary_scored(runs: int)
signal ball_stopped(pos: Vector3)

enum BallState { IDLE, IN_FLIGHT_TO_BATSMAN, IN_PLAY, CAUGHT, DEAD }

@export var ball_radius: float = 0.036 # 72mm diameter regulation cricket ball
@export var air_drag: float = 0.0028
@export var gravity: float = 9.81
@export var boundary_radius: float = 68.0

var current_state: BallState = BallState.IDLE
var velocity: Vector3 = Vector3.ZERO
var swing_acceleration: float = 0.0
var spin_deviation: float = 0.0
var has_bounced: bool = false
var bounce_position: Vector3 = Vector3.ZERO
var is_bat_contact: bool = false
var distance_traveled: float = 0.0

# Active pitch surface properties
var pitch_restitution: float = 0.78
var pitch_friction: float = 0.32
var pitch_seam_factor: float = 0.04
var pitch_spin_factor: float = 0.05

# Trajectory tracking for Hawkeye / DRS
var trajectory_points: Array[Vector3] = []
var predicted_points: Array[Vector3] = []

var ball_mesh: MeshInstance3D
var ball_mat: StandardMaterial3D

func _ready() -> void:
	load_pitch_properties(GameManager.selected_pitch)
	_build_ball_mesh()

func _build_ball_mesh() -> void:
	ball_mesh = MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = ball_radius
	sph.height = ball_radius * 2.0

	ball_mat = StandardMaterial3D.new()
	ball_mat.albedo_color = Color(1.0, 1.0, 1.0)
	if ResourceLoader.exists("res://assets/textures/pbr/ball_2k_albedo.png"):
		ball_mat.albedo_texture = load("res://assets/textures/pbr/ball_2k_albedo.png")
		ball_mat.normal_enabled = true
		ball_mat.normal_texture = load("res://assets/textures/pbr/ball_2k_normal.png")
		ball_mat.roughness_texture = load("res://assets/textures/pbr/ball_2k_roughness.png")
		ball_mat.ao_enabled = true
		ball_mat.ao_texture = load("res://assets/textures/pbr/ball_2k_ao.png")
	else:
		ball_mat.albedo_color = Color(0.76, 0.08, 0.12)
		ball_mat.roughness = 0.3

	sph.material = ball_mat
	ball_mesh.mesh = sph
	add_child(ball_mesh)

func load_pitch_properties(pitch_key: String) -> void:
	if DataManager.pitch_types.has(pitch_key):
		var p: Dictionary = DataManager.pitch_types[pitch_key]
		pitch_restitution = p["restitution"]
		pitch_friction = p["friction"]
		pitch_seam_factor = p["seam_factor"]
		pitch_spin_factor = p["spin_factor"]

func launch_delivery(start_pos: Vector3, initial_vel: Vector3, swing_acc: float, spin_dev: float) -> void:
	global_position = start_pos
	velocity = initial_vel
	swing_acceleration = swing_acc
	spin_deviation = spin_dev
	current_state = BallState.IN_FLIGHT_TO_BATSMAN
	has_bounced = false
	is_bat_contact = false
	bounce_position = Vector3.ZERO
	trajectory_points.clear()
	trajectory_points.append(start_pos)

func _physics_process(delta: float) -> void:
	if current_state == BallState.IDLE or current_state == BallState.DEAD:
		return
	
	# Gravity
	velocity.y -= gravity * delta
	
	# Air drag
	var speed: float = velocity.length()
	var drag_force: Vector3 = -velocity.normalized() * (air_drag * speed * speed)
	velocity += drag_force * delta
	
	# Lateral swing before bounce
	if not has_bounced and current_state == BallState.IN_FLIGHT_TO_BATSMAN:
		velocity.x += swing_acceleration * delta
	
	# Move position
	var next_pos: Vector3 = global_position + velocity * delta
	
	# Pitch / Ground Collision Check
	if next_pos.y <= ball_radius:
		next_pos.y = ball_radius
		_handle_ground_bounce(next_pos)
	
	global_position = next_pos
	trajectory_points.append(global_position)
	
	# Stumps Collision Check (Batsman Stumps at z = 10.06m)
	if current_state == BallState.IN_FLIGHT_TO_BATSMAN or current_state == BallState.IN_PLAY:
		if abs(global_position.z - 10.06) < 0.16 and abs(global_position.x) <= 0.14 and global_position.y <= 0.74:
			_trigger_stump_collision()
			return
			
	# Wicketkeeper Clean Catch Check
	if current_state == BallState.IN_FLIGHT_TO_BATSMAN and not is_bat_contact:
		if global_position.z >= 13.8:
			current_state = BallState.CAUGHT
			velocity = Vector3.ZERO
			ball_caught_by_keeper.emit()
			return
			
	# Boundary Scoring Check
	if current_state == BallState.IN_PLAY:
		var dist_from_center: float = Vector2(global_position.x, global_position.z).length()
		if dist_from_center >= boundary_radius:
			current_state = BallState.DEAD
			velocity = Vector3.ZERO
			if has_bounced:
				ball_boundary_scored.emit(4)
			else:
				ball_boundary_scored.emit(6)
			return
			
		# Ball slowing to a stop
		if global_position.y <= ball_radius + 0.01:
			velocity.x = move_toward(velocity.x, 0.0, pitch_friction * 14.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, pitch_friction * 14.0 * delta)
			if Vector2(velocity.x, velocity.z).length() < 0.2:
				velocity = Vector3.ZERO
				current_state = BallState.DEAD
				ball_stopped.emit(global_position)

func _handle_ground_bounce(contact_point: Vector3) -> void:
	if not has_bounced:
		has_bounced = true
		bounce_position = contact_point
		ball_bounced.emit(bounce_position, Vector3.UP)
		AudioManager.play_sfx("ball_bounce")
		
		# Apply spin or seam deviation immediately upon pitching
		if abs(spin_deviation) > 0.001:
			velocity.x += spin_deviation * (1.0 + pitch_spin_factor * 5.0)
		else:
			# Random subtle seam deviation based on pitch seam factor
			velocity.x += (randf() * 2.0 - 1.0) * pitch_seam_factor * 8.0
	
	# Normal bounce restitution and ground friction
	velocity.y = -velocity.y * pitch_restitution
	velocity.x *= (1.0 - pitch_friction * 0.4)
	velocity.z *= (1.0 - pitch_friction * 0.4)

func _trigger_stump_collision() -> void:
	current_state = BallState.DEAD
	velocity = Vector3(randf_range(-2, 2), randf_range(3, 6), randf_range(2, 5))
	ball_hit_stumps.emit()

func hit_by_bat(exit_velocity: Vector3) -> void:
	is_bat_contact = true
	current_state = BallState.IN_PLAY
	velocity = exit_velocity
	var speed_kmh: float = exit_velocity.length() * 3.6
	ball_hit_bat.emit(global_position, speed_kmh)

# scripts/physics/cricket_ball.gd
# Advanced 3D Cricket Ball Aerodynamics, Trajectory Recording & Pitch Interaction
class_name CricketBall
extends Node3D

signal ball_pitched(pos: Vector3, bounce_vel: Vector3)
signal ball_hit_bat(impact_pos: Vector3, timing_quality: String)
signal ball_hit_stumps(stump_id: int)
signal ball_hit_boundary(runs: int)
signal ball_dead(reason: String)

enum BallState {
	IN_HAND,
	IN_FLIGHT_BOWLED,
	AFTER_BOUNCE,
	IN_FLIGHT_BATTED,
	ROLLING_TURF,
	FIELDED,
	DEAD
}

@export var ball_radius: float = 0.036 # Standard 7.2cm cricket ball diameter

var state: BallState = BallState.IN_HAND
var velocity: Vector3 = Vector3.ZERO
var spin_rps: Vector3 = Vector3.ZERO # Spin rotations per second (X=Top/Backspin, Y=Turn, Z=Seam wobble)
var seam_angle_deg: float = 0.0 # Seam tilt for swing

# Aerodynamics constants
const GRAVITY: float = 9.81
const AIR_DENSITY: float = 1.225
const DRAG_COEFF: float = 0.42
const BALL_CROSS_SECTION: float = PI * 0.036 * 0.036
const MAGNUS_COEFF: float = 0.00045

var pitch_physics: PitchPhysics = PitchPhysics.new()
var has_bounced: bool = false
var has_hit_bat: bool = false
var bounce_count: int = 0
var trajectory_history: Array[Vector3] = []
var max_history_frames: int = 400

# Boundary radius from pitch center (0,0,0)
const BOUNDARY_RADIUS: float = 68.0

# 3D Visual Mesh
var mesh_instance: MeshInstance3D

func _ready() -> void:
	_create_ball_visual()

func _create_ball_visual() -> void:
	mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = ball_radius
	sphere.height = ball_radius * 2.0
	sphere.radial_segments = 24
	sphere.rings = 16
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.08, 0.08) # Rich crimson leather
	mat.roughness = 0.35
	mat.metallic = 0.05
	sphere.material = mat
	mesh_instance.mesh = sphere
	add_child(mesh_instance)
	
	# Visual white seam ring
	var seam = TorusMesh.new()
	seam.inner_radius = ball_radius * 0.96
	seam.outer_radius = ball_radius * 1.02
	seam.rings = 20
	seam.ring_segments = 6
	var seam_mat = StandardMaterial3D.new()
	seam_mat.albedo_color = Color(1.0, 1.0, 1.0)
	seam.material = seam_mat
	var seam_inst = MeshInstance3D.new()
	seam_inst.mesh = seam
	seam_inst.rotation_degrees = Vector3(90, 0, 0)
	mesh_instance.add_child(seam_inst)

func launch_delivery(start_pos: Vector3, target_velocity: Vector3, spin: Vector3, seam_tilt: float, pitch_type: PitchPhysics.PitchType) -> void:
	global_position = start_pos
	velocity = target_velocity
	spin_rps = spin
	seam_angle_deg = seam_tilt
	pitch_physics.set_pitch_type(pitch_type)
	
	state = BallState.IN_FLIGHT_BOWLED
	has_bounced = false
	has_hit_bat = false
	bounce_count = 0
	trajectory_history.clear()
	trajectory_history.append(global_position)
	visible = true

func hit_by_bat(exit_velocity: Vector3, hit_point: Vector3, quality: String) -> void:
	global_position = hit_point
	velocity = exit_velocity
	state = BallState.IN_FLIGHT_BATTED
	has_hit_bat = true
	# Add slight top or backspin based on elevation
	spin_rps = Vector3(exit_velocity.y * 0.5, exit_velocity.x * 0.2, 0.0)
	emit_signal("ball_hit_bat", hit_point, quality)

func _physics_process(delta: float) -> void:
	if state == BallState.IN_HAND or state == BallState.DEAD:
		return
	
	# 1. Aerodynamic Drag: Fd = 0.5 * rho * v^2 * Cd * A
	var speed = velocity.length()
	if speed > 0.01:
		var drag_force = 0.5 * AIR_DENSITY * (speed * speed) * DRAG_COEFF * BALL_CROSS_SECTION
		var drag_accel = (velocity / speed) * (drag_force / 0.16) # ball mass = 160g = 0.16kg
		velocity -= drag_accel * delta
	
	# 2. Gravity
	velocity.y -= GRAVITY * delta
	
	# 3. Magnus Effect (In-flight conventional/reverse swing and dip)
	if state == BallState.IN_FLIGHT_BOWLED and not has_bounced:
		# Swing lateral force: cross product of spin/seam tilt and forward velocity
		var swing_accel_x = sin(deg_to_rad(seam_angle_deg)) * (speed * 0.08)
		velocity.x += swing_accel_x * delta
		# Magnus dip or float
		var magnus_y = spin_rps.x * MAGNUS_COEFF * speed
		velocity.y += magnus_y * delta
	
	# Integrate position
	global_position += velocity * delta
	
	# Record trajectory for Hawkeye and Replay
	trajectory_history.append(global_position)
	if trajectory_history.size() > max_history_frames:
		trajectory_history.pop_front()
	
	# Rotate ball visual in direction of movement
	if speed > 0.1:
		mesh_instance.rotate_x(speed * delta * 2.0)
	
	# 4. Pitch & Ground Collision Check
	var pitch_surface_y = ball_radius
	if global_position.y <= pitch_surface_y:
		global_position.y = pitch_surface_y
		_handle_ground_contact()
	
	# 5. Boundary Check
	var dist_from_center = Vector2(global_position.x, global_position.z).length()
	if dist_from_center >= BOUNDARY_RADIUS:
		_handle_boundary_reached()
	
	# 6. Dead ball distance checks (behind wicketkeeper or too far)
	if global_position.z > 22.0 or absf(global_position.x) > 75.0 or global_position.y < -1.0:
		_conclude_ball("out_of_bounds")

func _handle_ground_contact() -> void:
	bounce_count += 1
	AudioManager.play_ball_bounce()
	
	# Inside 22-yard pitch strip (|x| <= 1.52m and -10.5m <= z <= 10.5m)
	var on_pitch = absf(global_position.x) <= 1.52 and absf(global_position.z) <= 10.5
	
	if not has_bounced and state == BallState.IN_FLIGHT_BOWLED:
		has_bounced = true
		state = BallState.AFTER_BOUNCE
		emit_signal("ball_pitched", global_position, velocity)
	
	if on_pitch:
		velocity = pitch_physics.calculate_bounce_velocity(velocity, spin_rps, seam_angle_deg)
	else:
		# Outfield grass bounce (higher damping, slight grass friction)
		velocity.y = -velocity.y * 0.52
		velocity.x *= 0.88
		velocity.z *= 0.88
	
	# If vertical bounce is very small, transition to turf rolling
	if absf(velocity.y) < 0.6:
		velocity.y = 0.0
		state = BallState.ROLLING_TURF
		# Turf rolling friction
		velocity *= 0.94

func _handle_boundary_reached() -> void:
	if state == BallState.DEAD:
		return
	state = BallState.DEAD
	# If ball landed directly over rope without bouncing on turf -> SIX (6)
	# If ball bounced or rolled across the rope -> FOUR (4)
	var runs = 6 if (bounce_count == 0 and has_hit_bat) else 4
	emit_signal("ball_hit_boundary", runs)

func _conclude_ball(reason: String) -> void:
	if state == BallState.DEAD:
		return
	state = BallState.DEAD
	emit_signal("ball_dead", reason)

func get_trajectory_points() -> Array[Vector3]:
	return trajectory_history

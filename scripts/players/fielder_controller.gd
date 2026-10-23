# scripts/players/fielder_controller.gd
# Dynamic Ball Pursuit AI, Ground Pickup, Aerial Catching & Preset Field Layouts
class_name FielderController
extends CricketPlayer

signal ball_fielded(fielder_name: String, is_catch: bool)

enum FieldPreset {
	BALANCED,
	ATTACKING,
	DEFENSIVE
}

@export var is_wicketkeeper: bool = false
@export var base_field_position: Vector3 = Vector3.ZERO

var ball_ref: CricketBall
var is_pursuing_ball: bool = false
var has_collected_ball: bool = false
var sprint_speed: float = 7.8 # m/s

func setup_fielder(ball: CricketBall, pos: Vector3, keeper: bool = false) -> void:
	ball_ref = ball
	is_wicketkeeper = keeper
	base_field_position = pos
	global_position = pos
	role = "Wicketkeeper" if keeper else "Fielder"
	is_pursuing_ball = false
	has_collected_ball = false
	
	if is_wicketkeeper:
		safe_look_at(Vector3(0, 0, 0))
		play_animation("keeper_crouch", 1.0, true)
	else:
		safe_look_at(Vector3(0, 0, 10.0))
		play_animation("fielder_ready", 1.0, true)

func reset_position() -> void:
	global_position = base_field_position
	is_pursuing_ball = false
	has_collected_ball = false
	if is_wicketkeeper:
		play_animation("keeper_crouch", 1.0, true)
		safe_look_at(Vector3(0, 0, 0))
	else:
		play_animation("fielder_ready", 1.0, true)
		safe_look_at(Vector3(0, 0, 10.0))

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if not ball_ref:
		return
	
	# Wicketkeeper logic behind stumps (stumps at z = 10.06m)
	if is_wicketkeeper:
		var ball_z = ball_ref.global_position.z
		# Delivery passes stumps cleanly without bat hit -> Keeper catches ball at z > 13.8m
		if not ball_ref.has_hit_bat and ball_z > 13.8 and not has_collected_ball:
			has_collected_ball = true
			play_animation("keeper_crouch", 1.5, false)
			ball_ref.state = CricketBall.BallState.FIELDED
			emit_signal("ball_fielded", player_name, false)
		return
	
	# Outfield & Ring Fielder Pursuit AI
	if ball_ref.state == CricketBall.BallState.IN_FLIGHT_BATTED or ball_ref.state == CricketBall.BallState.ROLLING_TURF:
		var dist_to_ball = global_position.distance_to(ball_ref.global_position)
		
		# If within sprint range and ball is moving
		if dist_to_ball < 28.0 and not has_collected_ball:
			is_pursuing_ball = true
			safe_look_at(ball_ref.global_position)
			
			# Sprint towards ball
			var move_dir = (ball_ref.global_position - global_position).normalized()
			global_position += move_dir * sprint_speed * delta
			play_animation("fielder_sprint", 1.4, true)
			
			# Aerial catch evaluation (within 1.3m and ball hasn't bounced on ground)
			if dist_to_ball <= 1.30 and ball_ref.bounce_count == 0 and ball_ref.has_hit_bat:
				has_collected_ball = true
				is_pursuing_ball = false
				ball_ref.state = CricketBall.BallState.FIELDED
				play_animation("fielder_slide_pickup", 1.2, false)
				emit_signal("ball_fielded", player_name, true) # CATCH OUT!
				return
			
			# Ground pickup evaluation (within 0.85m)
			if dist_to_ball <= 0.85 and not has_collected_ball:
				has_collected_ball = true
				is_pursuing_ball = false
				ball_ref.state = CricketBall.BallState.FIELDED
				play_animation("fielder_slide_pickup", 1.5, false)
				# Throw back to stumps after 0.4s
				get_tree().create_timer(0.4).timeout.connect(_throw_to_stumps)
				emit_signal("ball_fielded", player_name, false)

func _throw_to_stumps() -> void:
	play_animation("fielder_throw", 1.4, false)
	# Target striker stumps (z = 10.06) or non-striker (z = -10.06)
	var target_stumps = Vector3(0, 0.4, 10.06)
	safe_look_at(target_stumps)
	if ball_ref:
		var throw_vel = (target_stumps - global_position).normalized() * 26.0
		throw_vel.y = 4.5
		ball_ref.velocity = throw_vel
		ball_ref.state = CricketBall.BallState.IN_FLIGHT_BATTED

# Static Presets for 9 Fielders + 1 Keeper
static func get_field_positions(preset: FieldPreset) -> Array[Vector3]:
	match preset:
		FieldPreset.ATTACKING:
			return [
				Vector3(1.2, 0, 11.5),   # 1st Slip
				Vector3(2.4, 0, 11.2),   # 2nd Slip
				Vector3(4.8, 0, 9.8),    # Gully
				Vector3(12.0, 0, 5.0),   # Point
				Vector3(16.0, 0, -4.0),  # Cover
				Vector3(6.0, 0, -12.0),  # Mid-Off
				Vector3(-6.0, 0, -12.0), # Mid-On
				Vector3(-8.0, 0, 4.0),   # Short Mid-Wicket
				Vector3(-14.0, 0, 8.0)   # Square Leg
			]
		FieldPreset.DEFENSIVE:
			return [
				Vector3(38.0, 0, 12.0),  # Deep Point
				Vector3(42.0, 0, -15.0), # Deep Cover
				Vector3(12.0, 0, -48.0), # Long-Off
				Vector3(-12.0, 0, -48.0),# Long-On
				Vector3(-44.0, 0, -10.0),# Deep Mid-Wicket
				Vector3(-38.0, 0, 24.0), # Deep Square Leg
				Vector3(26.0, 0, 38.0),  # Third Man
				Vector3(-24.0, 0, 42.0), # Deep Fine Leg
				Vector3(14.0, 0, 4.0)    # Extra Cover
			]
		_: # BALANCED
			return [
				Vector3(2.2, 0, 11.5),   # Slip
				Vector3(16.0, 0, 8.0),   # Point
				Vector3(22.0, 0, -6.0),  # Cover
				Vector3(9.0, 0, -14.0),  # Mid-Off
				Vector3(-9.0, 0, -14.0), # Mid-On
				Vector3(-18.0, 0, -4.0), # Mid-Wicket
				Vector3(-16.0, 0, 9.0),  # Square Leg
				Vector3(32.0, 0, 36.0),  # Third Man
				Vector3(-28.0, 0, 38.0)  # Deep Fine Leg
			]

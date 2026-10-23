extends Node
class_name FieldingController

# FieldingController: Preset Field Layouts, Dynamic Ball Pursuit AI & Throws

signal catch_taken(fielder_name: String)
signal ball_fielded(fielder_name: String)

enum FieldPreset { BALANCED, ATTACKING, DEFENSIVE }

var active_preset: FieldPreset = FieldPreset.BALANCED
var fielders: Array[PlayerCharacter] = []
var wicketkeeper: PlayerCharacter
var ball: BallPhysics

var active_pursuer: PlayerCharacter = null
var is_pursuing: bool = false
var pursuit_target: Vector3 = Vector3.ZERO

# Field Preset Coordinate Layouts (9 Fielders)
const LAYOUT_BALANCED: Array[Vector3] = [
	Vector3(1.5, 0, 11.5),    # First Slip
	Vector3(14.0, 0, 8.0),    # Backward Point
	Vector3(22.0, 0, 0.0),    # Extra Cover
	Vector3(12.0, 0, -8.0),   # Mid-Off
	Vector3(-12.0, 0, -8.0),  # Mid-On
	Vector3(-22.0, 0, 0.0),   # Mid-Wicket
	Vector3(-16.0, 0, 8.0),   # Square Leg
	Vector3(45.0, 0, 42.0),   # Deep Third Man
	Vector3(-45.0, 0, 42.0)   # Deep Fine Leg
]

const LAYOUT_ATTACKING: Array[Vector3] = [
	Vector3(1.4, 0, 11.5),    # First Slip
	Vector3(2.6, 0, 11.8),    # Second Slip
	Vector3(5.5, 0, 11.0),    # Gully
	Vector3(6.5, 0, 6.0),     # Silly Point
	Vector3(-6.5, 0, 6.0),    # Short Leg
	Vector3(14.0, 0, 4.0),    # Cover Point
	Vector3(-14.0, 0, 4.0),   # Short Mid-Wicket
	Vector3(10.0, 0, -7.0),   # Mid-Off
	Vector3(-10.0, 0, -7.0)   # Mid-On
]

const LAYOUT_DEFENSIVE: Array[Vector3] = [
	Vector3(52.0, 0, 15.0),   # Deep Point
	Vector3(48.0, 0, -18.0),  # Deep Cover
	Vector3(20.0, 0, -52.0),  # Long-Off
	Vector3(-20.0, 0, -52.0), # Long-On
	Vector3(-48.0, 0, -18.0), # Deep Mid-Wicket
	Vector3(-52.0, 0, 15.0),  # Deep Square Leg
	Vector3(45.0, 0, 45.0),   # Third Man
	Vector3(-45.0, 0, 45.0),  # Fine Leg
	Vector3(18.0, 0, 6.0)     # Ring Cover
]

func init(fielding_players: Array[PlayerCharacter], keeper: PlayerCharacter, ball_inst: BallPhysics) -> void:
	fielders = fielding_players
	wicketkeeper = keeper
	ball = ball_inst

	# Set up keeper
	wicketkeeper.role = PlayerCharacter.PlayerRole.WICKETKEEPER
	wicketkeeper.global_position = Vector3(0, 0, 13.5)
	wicketkeeper.look_at_flat(Vector3(0, 0, 10.0))
	wicketkeeper.play_animation("keeper_crouch")

	apply_layout(FieldPreset.BALANCED)

func apply_layout(preset: FieldPreset) -> void:
	active_preset = preset
	var layout: Array[Vector3] = LAYOUT_BALANCED
	match preset:
		FieldPreset.BALANCED:
			layout = LAYOUT_BALANCED
		FieldPreset.ATTACKING:
			layout = LAYOUT_ATTACKING
		FieldPreset.DEFENSIVE:
			layout = LAYOUT_DEFENSIVE

	for i in range(min(fielders.size(), layout.size())):
		var f: PlayerCharacter = fielders[i]
		f.global_position = layout[i]
		f.look_at_flat(Vector3(0, 0, 9.05)) # Look at batsman
		f.play_animation("fielder_ready")

func _physics_process(delta: float) -> void:
	if ball and ball.current_state == BallPhysics.BallState.IN_PLAY:
		_process_pursuit(delta)
	else:
		is_pursuing = false
		active_pursuer = null

func _process_pursuit(delta: float) -> void:
	if not is_pursuing or active_pursuer == null:
		# Identify nearest fielder
		var best_fielder: PlayerCharacter = null
		var min_dist: float = 9999.0
		for f in fielders:
			var d: float = f.global_position.distance_to(ball.global_position)
			if d < min_dist:
				min_dist = d
				best_fielder = f
		
		if best_fielder:
			active_pursuer = best_fielder
			is_pursuing = true
			active_pursuer.play_animation("fielder_sprint", 1.4)

	if active_pursuer:
		# Pursue ball intercept position
		var to_ball: Vector3 = ball.global_position - active_pursuer.global_position
		to_ball.y = 0.0 # Maintain flat plane
		var dist: float = to_ball.length()

		active_pursuer.look_at_flat(ball.global_position)

		# Sprint speed: 8.2 m/s
		var sprint_speed: float = 8.2
		var move_step: float = sprint_speed * delta

		if dist > 0.85:
			active_pursuer.global_position += to_ball.normalized() * min(move_step, dist)
		else:
			# Within pickup/catch range!
			_handle_fielder_contact()

func _handle_fielder_contact() -> void:
	is_pursuing = false
	var ball_height: float = ball.global_position.y

	if ball_height > 0.5 and not ball.has_bounced:
		# Aerial Catch!
		ball.current_state = BallPhysics.BallState.DEAD
		ball.velocity = Vector3.ZERO
		active_pursuer.play_animation("celebration_wicket")
		catch_taken.emit(active_pursuer.player_name)
		GameManager.record_delivery(0, true, "Caught", false)
	else:
		# Ground slide pickup & throw
		active_pursuer.play_animation("fielder_ready")
		ball_fielded.emit(active_pursuer.player_name)
		# Throw ball back to stumps
		var throw_vel: Vector3 = (Vector3(0, 0.4, 10.06) - ball.global_position).normalized() * 24.0
		ball.velocity = throw_vel

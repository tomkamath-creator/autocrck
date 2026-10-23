# scripts/players/bowler_controller.gd
# Master Bowling System & Continuous Auto-Bowling AI Loop for CricStrike 3D
# Express Fast, Swing, and Spin variations with 3-step controls and automated loop.
class_name BowlerController
extends CricketPlayer

signal delivery_released(delivery_type: String, speed_kmh: float)
signal ball_completed(result_summary: String)

enum BowlingStyle {
	EXPRESS_FAST,
	FAST_MEDIUM,
	SWING_SPECIALIST,
	OFF_SPIN,
	LEG_SPIN
}

# 3-Step Control Values
var target_pitch_point: Vector3 = Vector3(0.1, 0.0, 5.5) # x: line, z: length
var swing_turn_amount: float = 0.0 # -1.0 (inswing/legbreak) to +1.0 (outswing/offbreak)
var release_accuracy: float = 1.0 # 1.0 = Perfect green zone, <0.7 = Mistimed/No-ball penalty

var current_style: BowlingStyle = BowlingStyle.EXPRESS_FAST
var ball_ref: CricketBall
var is_bowling_active: bool = false
var runup_timer: float = 0.0
const RUNUP_DURATION: float = 1.6
const RUNUP_START_POS: Vector3 = Vector3(0, 0, -22.0)
const CREASE_DELIVERY_POS: Vector3 = Vector3(0.4, 0.0, -10.0)

var is_ai_controlled: bool = true
var ready_cue_timer: float = 1.0
var ball_end_delay_timer: float = 0.0

func setup_bowler(ball: CricketBall, style: BowlingStyle = BowlingStyle.EXPRESS_FAST) -> void:
	ball_ref = ball
	current_style = style
	role = "Bowler"
	global_position = RUNUP_START_POS
	safe_look_at(Vector3(0, 0, 10.0))
	is_bowling_active = false
	ready_cue_timer = 1.0

func set_3step_parameters(pitch_pos: Vector3, swing: float, power: float) -> void:
	target_pitch_point = pitch_pos
	swing_turn_amount = clampf(swing, -1.0, 1.0)
	release_accuracy = clampf(power, 0.0, 1.0)

func start_delivery_sequence() -> void:
	if is_bowling_active:
		return
	is_bowling_active = true
	runup_timer = 0.0
	global_position = RUNUP_START_POS
	play_animation("runup", 1.4, true)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# Continuous Auto-Bowling Loop for Batting Mode
	if is_ai_controlled and not is_bowling_active:
		if ready_cue_timer > 0.0:
			ready_cue_timer -= delta
			if ready_cue_timer <= 0.0:
				_plan_ai_delivery()
				start_delivery_sequence()
	
	# Handle active runup and release
	if is_bowling_active:
		runup_timer += delta
		var p = runup_timer / RUNUP_DURATION
		
		# Move forward during approach sprint
		if p < 0.75:
			global_position = RUNUP_START_POS.lerp(CREASE_DELIVERY_POS, p / 0.75)
		elif p < 0.85:
			# Crease bound & delivery stride
			if animator.current_anim != "delivery_stride":
				play_animation("delivery_stride", 1.5, false)
		elif p >= 0.85 and ball_ref and ball_ref.state == CricketBall.BallState.IN_HAND:
			# Release cricket ball at apex of bowling arm
			_release_ball()
		
		if p >= 1.0:
			is_bowling_active = false
			play_animation("stance", 0.0, true)

func _plan_ai_delivery() -> void:
	# Select line & length variation
	# Zone: Full/Yorker (z=6.5 to 8.2), Good Length (z=4.8 to 6.2), Short (z=2.5 to 4.2)
	var lengths = [5.5, 6.0, 7.8, 3.8] # Good, Full, Yorker, Short
	var lines = [-0.15, 0.05, 0.22, -0.35] # Off stump, middle, outside off, leg
	
	var chosen_z = lengths[randi() % lengths.size()] + randf_range(-0.3, 0.3)
	var chosen_x = lines[randi() % lines.size()] + randf_range(-0.08, 0.08)
	target_pitch_point = Vector3(chosen_x, 0.0, chosen_z)
	
	# Swing/Turn variation
	swing_turn_amount = randf_range(-0.7, 0.7)
	release_accuracy = randf_range(0.85, 1.0)

func _release_ball() -> void:
	if not ball_ref:
		return
	
	var release_pos = global_position + Vector3(0.15, 2.15, 0.4) # High arm release point
	
	# Calculate required velocity to hit target_pitch_point
	# Forward distance = target_pitch_point.z - release_pos.z
	var dz = target_pitch_point.z - release_pos.z
	var dx = target_pitch_point.x - release_pos.x
	var dy = target_pitch_point.y - release_pos.y
	
	# Speed in km/h based on bowling style and release power
	var speed_kmh = 142.0
	var spin = Vector3.ZERO
	var seam_tilt = 0.0
	
	match current_style:
		BowlingStyle.EXPRESS_FAST:
			speed_kmh = lerp(145.0, 155.0, release_accuracy)
			seam_tilt = swing_turn_amount * 4.0
		BowlingStyle.FAST_MEDIUM:
			speed_kmh = lerp(130.0, 142.0, release_accuracy)
			seam_tilt = swing_turn_amount * 8.0
		BowlingStyle.SWING_SPECIALIST:
			speed_kmh = lerp(128.0, 138.0, release_accuracy)
			seam_tilt = swing_turn_amount * 18.0 # High swing curve
		BowlingStyle.OFF_SPIN:
			speed_kmh = lerp(85.0, 96.0, release_accuracy)
			spin = Vector3(5.0, -swing_turn_amount * 35.0, 0.0) # Sharp off break turn
		BowlingStyle.LEG_SPIN:
			speed_kmh = lerp(82.0, 92.0, release_accuracy)
			spin = Vector3(6.0, swing_turn_amount * 38.0, 0.0) # Leg break / Googly
	
	var forward_speed_ms = speed_kmh / 3.6
	var flight_time = dz / forward_speed_ms
	
	# Parabolic vertical velocity to hit target pitch point: dy = vy * t - 0.5 * g * t^2
	var vy = (dy + 0.5 * 9.81 * (flight_time * flight_time)) / flight_time
	var vx = dx / flight_time
	
	var initial_vel = Vector3(vx, vy, forward_speed_ms)
	
	# Launch ball with pitch surface physics
	ball_ref.launch_delivery(release_pos, initial_vel, spin, seam_tilt, PitchPhysics.PitchType.FLAT_DECK)
	emit_signal("delivery_released", BowlingStyle.keys()[current_style], speed_kmh)

# Call to cue next ball after 2.2s delay
func queue_next_delivery() -> void:
	ready_cue_timer = 2.2
	is_bowling_active = false
	if ball_ref:
		ball_ref.state = CricketBall.BallState.IN_HAND
		ball_ref.visible = false

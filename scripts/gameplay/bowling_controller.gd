extends Node
class_name BowlingController

# BowlingController: 3-Step Precision Delivery System & AI Auto-Bowling Loop

signal delivery_commenced()
signal delivery_released(speed_kmh: float, bowling_type: String)
signal delivery_completed(result: Dictionary)

enum BowlingStep { AIM_TARGET, SWING_METER, PACE_METER, RUNUP, IN_FLIGHT, COMPLETED }

var current_step: BowlingStep = BowlingStep.AIM_TARGET
var bowler: PlayerCharacter
var ball: BallPhysics

# Marker & Delivery Parameters
var target_marker_pos: Vector3 = Vector3(0.05, 0.015, 5.0) # Good length default
var locked_swing_value: float = 0.0 # -1.0 to +1.0
var locked_pace_power: float = 0.90 # 0.0 to 1.2 (sweetspot 0.85-1.0)
var is_no_ball: bool = false

# Bowling style attributes
var bowling_style: String = "RIGHT_ARM_FAST"
var max_speed_kmh: float = 145.0
var is_ai_controlled: bool = true

# AI Auto-Loop Timers
var ai_state_timer: float = 0.0
var is_awaiting_next_ball: bool = false

func init(bowler_char: PlayerCharacter, ball_inst: BallPhysics) -> void:
	bowler = bowler_char
	ball = ball_inst

	# Connect ball signals
	ball.ball_caught_by_keeper.connect(_on_keeper_caught)
	ball.ball_hit_stumps.connect(_on_stumps_hit)
	ball.ball_boundary_scored.connect(_on_boundary_scored)
	ball.ball_stopped.connect(_on_ball_stopped)

func set_bowler_attributes(style: String, max_speed: float, ai_control: bool) -> void:
	bowling_style = style
	max_speed_kmh = max_speed
	is_ai_controlled = ai_control

func _process(delta: float) -> void:
	if is_ai_controlled and not GameManager.match_completed:
		_process_ai_bowling_loop(delta)

func _process_ai_bowling_loop(delta: float) -> void:
	if is_awaiting_next_ball:
		ai_state_timer += delta
		if ai_state_timer >= 2.2:
			is_awaiting_next_ball = false
			ai_state_timer = 0.0
			start_ai_delivery()

func start_ai_delivery() -> void:
	current_step = BowlingStep.AIM_TARGET
	ai_state_timer = 0.0
	
	# Intelligent AI Line & Length selection based on match situation
	var roll: float = randf()
	if roll < 0.35:
		# Lethal Good Length channel outside off
		target_marker_pos = Vector3(randf_range(0.08, 0.22), 0.015, randf_range(3.5, 5.2))
	elif roll < 0.65:
		# Toe-crushing Yorker
		target_marker_pos = Vector3(randf_range(-0.05, 0.08), 0.015, randf_range(7.8, 8.6))
	elif roll < 0.85:
		# Aggressive Bouncer / Short ball
		target_marker_pos = Vector3(randf_range(-0.15, 0.25), 0.015, randf_range(1.2, 2.5))
	else:
		# Full toss / Driving length
		target_marker_pos = Vector3(randf_range(-0.02, 0.15), 0.015, randf_range(6.2, 7.2))
	
	locked_swing_value = randf_range(-0.6, 0.6)
	locked_pace_power = randf_range(0.85, 0.98) # Solid release
	is_no_ball = randf() < 0.03
	
	_trigger_runup_sequence()

func _trigger_runup_sequence() -> void:
	current_step = BowlingStep.RUNUP
	delivery_commenced.emit()
	
	# Position bowler at start of run-up (-18m)
	bowler.global_position = Vector3(0.35, 0.0, -18.0)
	bowler.look_at_flat(Vector3(0, 0, 10.0))
	bowler.play_animation("runup", 1.2)
	
	# Tween bowler sprinting into crease
	var tween := create_tween()
	tween.tween_property(bowler, "global_position:z", -8.5, 1.6)
	tween.finished.connect(_on_runup_reached_crease)

func _on_runup_reached_crease() -> void:
	bowler.play_animation("delivery_stride", 1.5)
	
	# Release ball at apex of windmill arm (0.35s after stride begin)
	var timer := get_tree().create_timer(0.32)
	timer.timeout.connect(_release_ball)

func _release_ball() -> void:
	current_step = BowlingStep.IN_FLIGHT
	
	var release_pos := Vector3(bowler.global_position.x + 0.15, 2.15, bowler.global_position.z + 0.4)
	var speed_mps: float = (max_speed_kmh / 3.6) * locked_pace_power
	
	# Calculate physics vector to hit target marker precisely
	var dist_z: float = target_marker_pos.z - release_pos.z
	var flight_time: float = dist_z / speed_mps
	
	var vx: float = (target_marker_pos.x - release_pos.x) / flight_time
	var vy: float = ((target_marker_pos.y - release_pos.y) + 0.5 * 9.81 * flight_time * flight_time) / flight_time
	var vz: float = speed_mps
	
	var initial_vel := Vector3(vx, vy, vz)
	var swing_acc: float = 0.0
	var spin_dev: float = 0.0
	
	if "FAST" in bowling_style:
		swing_acc = locked_swing_value * 3.4 # Lateral swing m/s^2
	else:
		spin_dev = locked_swing_value * 2.6 # Spin deviation off turf
	
	ball.launch_delivery(release_pos, initial_vel, swing_acc, spin_dev)
	delivery_released.emit(max_speed_kmh * locked_pace_power, bowling_style)

func _on_keeper_caught() -> void:
	if current_step == BowlingStep.IN_FLIGHT:
		current_step = BowlingStep.COMPLETED
		delivery_completed.emit({"result": "DOT", "runs": 0, "is_wicket": false})
		GameManager.record_delivery(0, false, "", is_no_ball)
		_tee_up_next_ball()

func _on_stumps_hit() -> void:
	current_step = BowlingStep.COMPLETED
	bowler.play_animation("celebration_wicket", 1.2)
	delivery_completed.emit({"result": "BOWLED", "runs": 0, "is_wicket": true})
	GameManager.record_delivery(0, true, "Bowled", false)
	_tee_up_next_ball()

func _on_boundary_scored(runs: int) -> void:
	current_step = BowlingStep.COMPLETED
	delivery_completed.emit({"result": "BOUNDARY", "runs": runs, "is_wicket": false})
	GameManager.record_delivery(runs, false, "", false)
	_tee_up_next_ball()

func _on_ball_stopped(pos: Vector3) -> void:
	if current_step == BowlingStep.IN_FLIGHT or current_step == BowlingStep.AIM_TARGET:
		return
	current_step = BowlingStep.COMPLETED
	var runs_run: int = randi_range(1, 2)
	delivery_completed.emit({"result": "RUNS", "runs": runs_run, "is_wicket": false})
	GameManager.record_delivery(runs_run, false, "", false)
	_tee_up_next_ball()

func _tee_up_next_ball() -> void:
	is_awaiting_next_ball = true
	ai_state_timer = 0.0

func get_length_zone(z: float) -> Dictionary:
	if z >= 7.5:
		return {"name": "Yorker", "color": Color(0.9, 0.15, 0.15)}
	elif z >= 5.5:
		return {"name": "Full", "color": Color(0.15, 0.85, 0.95)}
	elif z >= 2.5:
		return {"name": "Good Length", "color": Color(0.15, 0.85, 0.25)}
	else:
		return {"name": "Short / Bouncer", "color": Color(0.95, 0.55, 0.1)}

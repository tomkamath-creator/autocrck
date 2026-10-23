# scripts/players/batsman_controller.gd
# Elite Batting Mechanics & Millisecond-Precision Timing Engine for CricStrike 3D
# Evaluates ball arrival at strike plane (z = 9.05m) across 8 joystick sectors and LOFT/DRIVE/DEFEND.
class_name BatsmanController
extends CricketPlayer

signal shot_executed(shot_type: String, timing_quality: String, exit_speed_kmh: float, sector_name: String)

# Strike plane z position at striker crease
const STRIKE_PLANE_Z: float = 9.05

enum ShotType {
	NONE,
	DRIVE,
	LOFT,
	DEFEND
}

var current_shot_intent: ShotType = ShotType.NONE
var shot_direction_vector: Vector2 = Vector2(0, 1) # Default straight ahead
var has_attempted_shot: bool = false
var ball_ref: CricketBall

# 8 Directional Sectors (Angles in degrees from bowler direction)
# (0 deg = Straight down ground / Long-On/Off, 90 deg = Point/Cover, etc.)
const SECTORS := [
	{"name": "Long-Off", "min_deg": -30.0, "max_deg": 0.0},
	{"name": "Cover", "min_deg": 0.0, "max_deg": 45.0},
	{"name": "Point", "min_deg": 45.0, "max_deg": 90.0},
	{"name": "Third Man", "min_deg": 90.0, "max_deg": 135.0},
	{"name": "Fine Leg", "min_deg": 135.0, "max_deg": 180.0},
	{"name": "Square Leg", "min_deg": -180.0, "max_deg": -135.0},
	{"name": "Mid-Wicket", "min_deg": -135.0, "max_deg": -60.0},
	{"name": "Long-On", "min_deg": -60.0, "max_deg": -30.0}
]

func setup_batsman(ball: CricketBall) -> void:
	ball_ref = ball
	role = "Batsman"
	global_position = Vector3(0.25, 0.0, STRIKE_PLANE_Z)
	safe_look_at(Vector3(0, 0, -10.0))
	has_attempted_shot = false
	current_shot_intent = ShotType.NONE
	play_animation("stance", 1.0, true)

func set_joystick_input(dir: Vector2) -> void:
	if dir.length_squared() > 0.05:
		shot_direction_vector = dir.normalized()

func trigger_shot_action(action_type: ShotType) -> void:
	if has_attempted_shot:
		return
	current_shot_intent = action_type
	has_attempted_shot = true
	_execute_bat_swing()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# If delivery is incoming, check proximity to strike plane
	if ball_ref and ball_ref.state == CricketBall.BallState.AFTER_BOUNCE:
		var ball_z = ball_ref.global_position.z
		# If player has not tapped action button and ball passed strike plane -> Automatic Leave / Beaten
		if not has_attempted_shot and ball_z > STRIKE_PLANE_Z + 0.35:
			has_attempted_shot = true
			play_animation("leave", 1.2, false)
			emit_signal("shot_executed", "LEAVE", "MISSED", 0.0, "None")

func _execute_bat_swing() -> void:
	if not ball_ref:
		return
	
	var ball_pos = ball_ref.global_position
	var ball_vz = ball_ref.velocity.z
	
	# Calculate arrival timing delta in milliseconds: delta_t = (z_strike - z_ball) / vz
	var timing_ms = 0.0
	if absf(ball_vz) > 1.0:
		var time_to_plane_sec = (STRIKE_PLANE_Z - ball_pos.z) / ball_vz
		timing_ms = time_to_plane_sec * 1000.0 # Positive: early, Negative: late
	else:
		timing_ms = 999.0
	
	var abs_timing = absf(timing_ms)
	var timing_quality = "MISSED"
	var exit_speed_mult = 0.0
	var edge_deviation = 0.0
	var is_sweetspot = false
	
	# Precision Timing Evaluation:
	# PERFECT: <= 26ms (Exit Speed 130 - 155 km/h, sweetspot crack)
	# GOOD / EARLY / LATE: 27 - 62ms (80 - 90% speed)
	# TOO EARLY / TOO LATE: 63 - 115ms (sliced edge)
	# MISSED / BEATEN: > 115ms
	if abs_timing <= 26.0:
		timing_quality = "PERFECT"
		exit_speed_mult = randf_range(1.0, 1.15)
		is_sweetspot = true
	elif abs_timing <= 62.0:
		timing_quality = "GOOD" if abs_timing <= 42.0 else ("EARLY" if timing_ms > 0 else "LATE")
		exit_speed_mult = randf_range(0.80, 0.90)
		is_sweetspot = true
	elif abs_timing <= 115.0:
		timing_quality = "TOO EARLY" if timing_ms > 0 else "TOO LATE"
		exit_speed_mult = randf_range(0.40, 0.65)
		edge_deviation = randf_range(-18.0, 18.0)
		is_sweetspot = false
	else:
		timing_quality = "BEATEN"
		exit_speed_mult = 0.0
	
	# Determine sector from joystick vector
	var angle_deg = rad_to_deg(atan2(shot_direction_vector.x, -shot_direction_vector.y))
	var sector_name = _get_sector_name(angle_deg)
	
	# Select animation based on action and sector
	var anim_to_play = "front_foot_drive"
	match current_shot_intent:
		ShotType.DEFEND:
			anim_to_play = "defend_forward"
		ShotType.LOFT:
			if sector_name in ["Mid-Wicket", "Square Leg"]:
				anim_to_play = "helicopter_shot" if randf() > 0.4 else "pull_shot"
			else:
				anim_to_play = "lofted_drive"
		ShotType.DRIVE:
			if sector_name in ["Point", "Third Man"]:
				anim_to_play = "cut_shot"
			elif sector_name in ["Mid-Wicket", "Square Leg"]:
				anim_to_play = "pull_shot"
			else:
				anim_to_play = "front_foot_drive"
	
	play_animation(anim_to_play, 1.4, false)
	
	# If timing was inside hitting window (not beaten)
	if exit_speed_mult > 0.05 and absf(ball_pos.x - global_position.x) < 1.3:
		# Calculate exit trajectory
		AudioManager.play_bat_crack(is_sweetspot)
		
		# Base exit velocity: 135 km/h = 37.5 m/s
		var base_speed_ms = 38.5 * exit_speed_mult
		var elevation_deg = 0.0
		if current_shot_intent == ShotType.LOFT:
			elevation_deg = randf_range(24.0, 38.0) if timing_quality != "TOO EARLY" else randf_range(45.0, 65.0) # Sliced skyer if too early
		elif current_shot_intent == ShotType.DRIVE:
			elevation_deg = randf_range(1.5, 6.0) # Hugs the turf
		else: # DEFEND
			base_speed_ms *= 0.15
			elevation_deg = 2.0
		
		var rad_elev = deg_to_rad(elevation_deg)
		var target_angle_rad = deg_to_rad(angle_deg + edge_deviation)
		
		var exit_vel = Vector3(
			sin(target_angle_rad) * cos(rad_elev) * base_speed_ms,
			sin(rad_elev) * base_speed_ms,
			-cos(target_angle_rad) * cos(rad_elev) * base_speed_ms
		)
		
		ball_ref.hit_by_bat(exit_vel, ball_pos, timing_quality)
		var exit_kmh = base_speed_ms * 3.6
		emit_signal("shot_executed", anim_to_play, timing_quality, exit_kmh, sector_name)
	else:
		# Missed / Beaten
		emit_signal("shot_executed", anim_to_play, "MISSED", 0.0, sector_name)

func _get_sector_name(deg: float) -> String:
	for s in SECTORS:
		if deg >= s["min_deg"] and deg < s["max_deg"]:
			return s["name"]
	return "Long-Off"

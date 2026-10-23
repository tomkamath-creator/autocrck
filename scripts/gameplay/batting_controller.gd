extends Node
class_name BattingController

# BattingController: Millisecond Precision Timing Engine & 360-Degree Shot Placement

signal shot_executed(timing_name: String, exit_speed_kmh: float, shot_sector: String)

@export var popping_crease_z: float = 9.05
@export var ideal_strike_dist: float = 0.45

var batsman: PlayerCharacter
var ball: BallPhysics

# 8 Sectors Mapping
const SECTOR_NAMES: Array[String] = [
	"Third Man", "Point", "Cover", "Long-Off",
	"Long-On", "Mid-Wicket", "Square Leg", "Fine Leg"
]

func init(batsman_char: PlayerCharacter, ball_inst: BallPhysics) -> void:
	batsman = batsman_char
	ball = ball_inst

func execute_shot(shot_type: String, joystick_dir: Vector2) -> Dictionary:
	if not ball or ball.current_state != BallPhysics.BallState.IN_FLIGHT_TO_BATSMAN:
		return {"success": false, "reason": "No active delivery in flight"}
	
	# Calculate millisecond precision timing window
	var ball_pos: Vector3 = ball.global_position
	var ball_vz: float = ball.velocity.z
	
	if ball_vz <= 1.0:
		return {"success": false, "reason": "Ball has stopped or reversed"}
	
	var dist_to_crease: float = popping_crease_z - ball_pos.z
	var time_to_crease_sec: float = dist_to_crease / ball_vz
	var timing_ms: float = time_to_crease_sec * 1000.0
	
	var timing_rating: String = "MISSED"
	var speed_multiplier: float = 0.0
	var is_edge: bool = false
	
	var abs_ms: float = abs(timing_ms)
	if abs_ms <= 26.0:
		timing_rating = "PERFECT"
		speed_multiplier = 1.0
	elif abs_ms <= 62.0:
		timing_rating = "EARLY" if timing_ms > 0 else "LATE"
		speed_multiplier = 0.85
	elif abs_ms <= 115.0:
		timing_rating = "TOO_EARLY" if timing_ms > 0 else "TOO_LATE"
		speed_multiplier = 0.55
		is_edge = randf() < 0.65
	else:
		timing_rating = "MISSED"
		speed_multiplier = 0.0
	
	if timing_rating == "MISSED":
		batsman.play_animation("leave")
		shot_executed.emit("MISSED", 0.0, "None")
		return {"success": false, "timing": "MISSED"}
	
	# Compute shot trajectory & angle from joystick
	var aim_angle: float = 0.0
	if joystick_dir.length() > 0.15:
		aim_angle = atan2(-joystick_dir.x, -joystick_dir.y) # Forward = negative Y
	else:
		aim_angle = 0.0 # Straight down the ground default
	
	var sector_idx: int = int(floor(posmod(rad_to_deg(aim_angle) + 22.5, 360.0) / 45.0))
	var sector_name: String = SECTOR_NAMES[clampi(sector_idx, 0, 7)]
	
	# Determine exit speed and elevation
	var base_speed: float = 0.0
	var elevation_deg: float = 0.0
	var anim_name: String = "front_foot_drive"
	
	match shot_type:
		"DRIVE":
			base_speed = randf_range(34.0, 42.0) # 122 - 151 km/h
			elevation_deg = randf_range(4.0, 9.0) # Hugs the turf
			if aim_angle < -0.8:
				anim_name = "cut_shot"
			elif aim_angle > 0.8:
				anim_name = "pull_shot"
			else:
				anim_name = "front_foot_drive"
		"LOFT":
			base_speed = randf_range(38.0, 46.0) # 136 - 165 km/h
			elevation_deg = randf_range(28.0, 36.0) # Clearing fielders
			if abs(aim_angle) < 0.5:
				anim_name = "lofted_drive"
			elif aim_angle > 0.8:
				anim_name = "helicopter_shot" if randf() < 0.5 else "pull_shot"
			else:
				anim_name = "lofted_drive"
		"DEFEND":
			base_speed = randf_range(3.0, 7.0)
			elevation_deg = 2.0
			anim_name = "defend_forward"
	
	var final_speed: float = base_speed * speed_multiplier
	if is_edge:
		# Thick outside or inside edge deviation
		aim_angle += deg_to_rad(randf_range(-45.0, 45.0))
		elevation_deg = randf_range(15.0, 45.0)
		final_speed *= 0.6
	
	# Calculate 3D velocity vector
	var rad_elev: float = deg_to_rad(elevation_deg)
	var horiz_speed: float = final_speed * cos(rad_elev)
	var exit_vel := Vector3(
		-sin(aim_angle) * horiz_speed,
		final_speed * sin(rad_elev),
		-cos(aim_angle) * horiz_speed
	)
	
	batsman.play_animation(anim_name, 1.4)
	ball.hit_by_bat(exit_vel)
	AudioManager.play_sfx("bat_crack", 1.0 if timing_rating == "PERFECT" else 0.85)
	
	var exit_speed_kmh: float = final_speed * 3.6
	shot_executed.emit(timing_rating, exit_speed_kmh, sector_name)
	
	return {
		"success": true,
		"timing": timing_rating,
		"timing_ms": timing_ms,
		"speed_kmh": exit_speed_kmh,
		"sector": sector_name
	}

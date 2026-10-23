# scripts/core/drs_manager.gd
# DRS (Decision Review System), UltraEdge Snickometer & Hawkeye 3D Ball Tracking Engine
extends Node

signal drs_review_started(review_type: String)
signal drs_step_updated(step_name: String, details: Dictionary)
signal drs_review_concluded(decision: String, overturned: bool)

# Hawkeye Stump Target Coordinates (Striker End z = 10.06m)
# Stumps width: x from -0.114m to +0.114m, height: y from 0.0m to 0.71m
const STUMP_Z: float = 10.06
const STUMP_MIN_X: float = -0.114
const STUMP_MAX_X: float = 0.114
const STUMP_MAX_Y: float = 0.71

func evaluate_hawkeye_lbw(pitch_point: Vector3, impact_point: Vector3, post_impact_velocity: Vector3) -> Dictionary:
	# 1. Pitching line (|x| <= 1.52m is on pitch, |x| <= 0.15m is directly in line with stumps)
	var pitched_status = "In Line"
	if pitch_point.x > 0.15:
		pitched_status = "Outside Off"
	elif pitch_point.x < -0.15:
		pitched_status = "Outside Leg"
	
	# 2. Impact point with batsman pad
	var impact_status = "In Line"
	if absf(impact_point.x) > 0.18:
		impact_status = "Outside Off" if impact_point.x > 0 else "Outside Leg"
	
	# 3. Project trajectory to stumps (z = 10.06)
	var dz = STUMP_Z - impact_point.z
	var projected_pos = impact_point
	if absf(post_impact_velocity.z) > 0.5:
		var t = dz / post_impact_velocity.z
		projected_pos.x = impact_point.x + post_impact_velocity.x * t
		projected_pos.y = impact_point.y + post_impact_velocity.y * t - 0.5 * 9.81 * (t * t)
	
	var wickets_status = "Missing"
	var is_hitting_x = projected_pos.x >= (STUMP_MIN_X - 0.036) and projected_pos.x <= (STUMP_MAX_X + 0.036)
	var is_hitting_y = projected_pos.y >= 0.04 and projected_pos.y <= (STUMP_MAX_Y + 0.036)
	
	if is_hitting_x and is_hitting_y:
		if absf(projected_pos.x - STUMP_MIN_X) < 0.02 or absf(projected_pos.x - STUMP_MAX_X) < 0.02:
			wickets_status = "Umpire's Call"
		else:
			wickets_status = "Hitting"
	
	return {
		"pitch_point": pitch_point,
		"impact_point": impact_point,
		"projected_stump_hit": projected_pos,
		"pitched": pitched_status,
		"impact": impact_status,
		"wickets": wickets_status,
		"is_out": (pitched_status != "Outside Leg") and (impact_status == "In Line") and (wickets_status == "Hitting")
	}

# UltraEdge / Snickometer waveform generation
# Returns array of audio amplitudes (0.0 to 1.0) along frame timeline
func generate_snickometer_waveform(frames: int, edge_frame_idx: int = -1) -> Array[float]:
	var waveform: Array[float] = []
	for i in range(frames):
		if edge_frame_idx >= 0 and abs(i - edge_frame_idx) <= 5:
			# Sharp acoustic high-frequency spike on bat edge
			var dist = abs(i - edge_frame_idx)
			var spike = (1.0 - (dist / 6.0)) * randf_range(0.75, 1.0)
			waveform.append(spike)
		else:
			# Clean flat baseline ambient line
			waveform.append(randf_range(0.02, 0.08))
	return waveform

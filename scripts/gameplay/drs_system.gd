extends Node
class_name DRSSystem

# DRSSystem: Hawkeye 3D Ball Tracking Prediction & UltraEdge / Snickometer Audio Waveform

signal drs_completed(verdict: String, hawkeye_data: Dictionary)

var ball: BallPhysics

func init(ball_inst: BallPhysics) -> void:
	ball = ball_inst

func evaluate_lbw_review() -> Dictionary:
	var bounce_pos: Vector3 = ball.bounce_position
	var is_pitched_in_line: bool = abs(bounce_pos.x) <= 0.14
	var pitch_verdict: String = "In Line" if is_pitched_in_line else ("Outside Off" if bounce_pos.x > 0 else "Outside Leg")

	var impact_pos: Vector3 = ball.global_position
	var is_impact_in_line: bool = abs(impact_pos.x) <= 0.14
	var impact_verdict: String = "In Line" if is_impact_in_line else "Outside Off"

	# Hawkeye trajectory projection to stumps plane at z = 10.06m
	var projected_stumps_x: float = impact_pos.x + ball.velocity.x * ((10.06 - impact_pos.z) / max(ball.velocity.z, 0.1))
	var projected_stumps_y: float = impact_pos.y + ball.velocity.y * ((10.06 - impact_pos.z) / max(ball.velocity.z, 0.1))

	var is_hitting_wickets: bool = abs(projected_stumps_x) <= 0.12 and projected_stumps_y <= 0.72 and projected_stumps_y >= 0.05
	var wickets_verdict: String = "Hitting" if is_hitting_wickets else "Missing"

	var final_verdict: String = "OUT" if (is_pitched_in_line and is_impact_in_line and is_hitting_wickets) else "NOT OUT"

	var hawkeye_data: Dictionary = {
		"pitched": pitch_verdict,
		"impact": impact_verdict,
		"wickets": wickets_verdict,
		"final_verdict": final_verdict,
		"projected_target": Vector3(projected_stumps_x, projected_stumps_y, 10.06),
		"ultraedge_waveform": generate_ultraedge_samples(ball.is_bat_contact)
	}

	drs_completed.emit(final_verdict, hawkeye_data)
	return hawkeye_data

func generate_ultraedge_samples(contact_occurred: bool) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(64)
	
	for i in range(64):
		# Ambient audio floor noise
		var noise: float = randf_range(-0.06, 0.06)
		
		# Sharp acoustic spike at frame 32 if bat touched ball
		var spike: float = 0.0
		if contact_occurred:
			var dist_from_impact: float = abs(float(i) - 32.0)
			if dist_from_impact < 8.0:
				var decay: float = exp(-dist_from_impact * 0.4)
				spike = sin(dist_from_impact * 2.2) * 0.95 * decay
		
		samples[i] = clampf(noise + spike, -1.0, 1.0)
	
	return samples

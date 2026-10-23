# scripts/physics/pitch_physics.gd
# Pitch Surface Physics & Aerodynamic Characteristics for CricStrike 3D
class_name PitchPhysics
extends RefCounted

enum PitchType {
	GREEN_TURF,
	DUSTY,
	FLAT_DECK,
	WET
}

var current_pitch: PitchType = PitchType.FLAT_DECK

# Restitution (Bounce), Friction (Skid/Slowdown), Seam Deviation, Spin Grip
var restitution: float = 0.78
var friction: float = 0.12
var seam_factor: float = 0.03
var spin_grip_factor: float = 1.0
var pitch_color: Color = Color(0.76, 0.68, 0.48) # Default tan/straw turf

func set_pitch_type(type: PitchType) -> void:
	current_pitch = type
	match current_pitch:
		PitchType.GREEN_TURF:
			restitution = 0.84 # High bounce
			friction = 0.10
			seam_factor = 0.08 # Sharp seam movement
			spin_grip_factor = 0.85
			pitch_color = Color(0.40, 0.62, 0.28) # Vibrant green tinged turf
		PitchType.DUSTY:
			restitution = 0.65 # Moderate/low bounce
			friction = 0.22 # Dry surface friction
			seam_factor = 0.02
			spin_grip_factor = 1.85 # High spin grip & sharp turn
			pitch_color = Color(0.72, 0.58, 0.38) # Dry dusty brown
		PitchType.FLAT_DECK:
			restitution = 0.78 # True consistent bounce
			friction = 0.09
			seam_factor = 0.02 # Minimal seam
			spin_grip_factor = 0.95
			pitch_color = Color(0.82, 0.75, 0.55) # Hard baked straw
		PitchType.WET:
			restitution = 0.55 # Low bounce
			friction = 0.05 # Skidding trajectory
			seam_factor = 0.06
			spin_grip_factor = 0.70 # Ball skids on wet surface
			pitch_color = Color(0.35, 0.42, 0.25) # Dark damp greenish mud

func calculate_bounce_velocity(incoming_vel: Vector3, spin_rps: Vector3, seam_angle_deg: float) -> Vector3:
	var out_vel = incoming_vel
	
	# Normal bounce response with pitch restitution
	out_vel.y = -incoming_vel.y * restitution
	
	# Horizontal friction / skid
	out_vel.x *= (1.0 - friction)
	out_vel.z *= (1.0 - friction * 0.5)
	
	# Seam deviation on landing
	if absf(seam_angle_deg) > 0.5:
		var seam_kick = sin(deg_to_rad(seam_angle_deg)) * seam_factor * incoming_vel.length()
		out_vel.x += seam_kick
	
	# Spin deviation on landing (spin_rps.y represents off/leg break rotation)
	if absf(spin_rps.y) > 0.1:
		var turn_kick = spin_rps.y * spin_grip_factor * 0.045
		out_vel.x += turn_kick
		# Topspin / Backspin effect on bounce height & carry
		out_vel.y += spin_rps.x * 0.02 * restitution
	
	return out_vel

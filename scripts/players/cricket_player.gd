# scripts/players/cricket_player.gd
# Base Kinematic Character Controller for CricStrike 3D
# Enforces strict upright constraints (rotation.x = 0, rotation.z = 0) and flat-plane look_at.
class_name CricketPlayer
extends CharacterBody3D

@export var role: String = "Batsman" # Batsman, Bowler, Wicketkeeper, Fielder, Umpire
@export var team_name: String = "India"
@export var player_name: String = "V. Kohli"
@export var jersey_number: int = 18
@export var build_type: String = "Athletic" # Athletic, Slim, Heavy
@export var skin_tone: int = 1

var animator: CricketAnimator
var model_node: Node3D

func _ready() -> void:
	_setup_model()

func _setup_model() -> void:
	# Clear old model if any
	for c in get_children():
		if c is Node3D and c.name.begins_with("PlayerModel"):
			c.queue_free()
	
	model_node = PlayerMeshBuilder.build_player_model(role, team_name, player_name, jersey_number, build_type, skin_tone)
	add_child(model_node)
	
	animator = CricketAnimator.new()
	animator.init(model_node)
	
	# Initial pose by role
	match role:
		"Batsman":
			animator.play("stance", 1.0, true)
		"Bowler":
			animator.play("runup", 0.0, true)
		"Wicketkeeper":
			animator.play("keeper_crouch", 1.0, true)
		"Fielder":
			animator.play("fielder_ready", 1.0, true)
		"Umpire":
			animator.play("stance", 0.0, true)

func _physics_process(delta: float) -> void:
	# ----------------- KINEMATIC SAFEGUARDS -----------------
	# Hardcode rotation.x and rotation.z to strictly 0.0 to eliminate pitch-tilt/belly-flop glitches
	rotation.x = 0.0
	rotation.z = 0.0
	
	if animator:
		animator.update(delta)

# Safe flat-plane Look-At targeting Vector3(target.x, global_position.y, target.z)
func safe_look_at(target: Vector3) -> void:
	var flat_target = Vector3(target.x, global_position.y, target.z)
	if global_position.distance_squared_to(flat_target) > 0.001:
		look_at(flat_target, Vector3.UP)
		rotation.x = 0.0
		rotation.z = 0.0

func play_animation(anim_name: String, speed: float = 1.0, loop: bool = false) -> void:
	if animator:
		animator.play(anim_name, speed, loop)

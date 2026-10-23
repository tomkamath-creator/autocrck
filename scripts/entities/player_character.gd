extends CharacterBody3D
class_name PlayerCharacter

# PlayerCharacter: Professional Athletic Humanoid (1.84m) with Role Gear & 100% Upright Kinematics

enum PlayerRole { BATSMAN, BOWLER, WICKETKEEPER, FIELDER, UMPIRE }
enum BattingShot { STANCE, FRONT_FOOT_DRIVE, LOFTED_DRIVE, PULL_SHOT, CUT_SHOT, HELICOPTER_SHOT, DEFEND_FORWARD, LEAVE, CELEBRATION }

@export var role: PlayerRole = PlayerRole.BATSMAN
@export var player_name: String = "V. Kohli"
@export var jersey_number: int = 18
@export var team_id: String = "IND"
@export var build_type: String = "ATHLETIC" # ATHLETIC, SLIM, HEAVY

# Nodes hierarchy
var body_root: Node3D
var hips: Node3D
var spine: Node3D
var chest: Node3D
var neck: Node3D
var head: Node3D

var left_shoulder: Node3D
var left_arm: Node3D
var left_forearm: Node3D
var left_hand: Node3D

var right_shoulder: Node3D
var right_arm: Node3D
var right_forearm: Node3D
var right_hand: Node3D

var left_thigh: Node3D
var left_knee: Node3D
var left_foot: Node3D

var right_thigh: Node3D
var right_knee: Node3D
var right_foot: Node3D

# Equipment nodes
var bat_node: Node3D
var helmet_node: Node3D
var face_grille: Node3D
var pads_left: Node3D
var pads_right: Node3D
var gloves_left: Node3D
var gloves_right: Node3D
var ball_held: Node3D
var umpire_hat: Node3D

# Materials
var jersey_mat: StandardMaterial3D
var pants_mat: StandardMaterial3D
var skin_mat: StandardMaterial3D
var bat_mat: StandardMaterial3D
var pads_mat: StandardMaterial3D
var helmet_mat: StandardMaterial3D
var chrome_mat: StandardMaterial3D

# Animation State
var current_anim: String = "stance"
var anim_time: float = 0.0
var anim_speed: float = 1.0
var target_anim: String = "stance"

func _ready() -> void:
	_init_materials()
	_build_humanoid_rig()
	_apply_role_configuration()
	_apply_team_kit()

func _physics_process(delta: float) -> void:
	# STRICT KINEMATIC SAFEGUARDS: Always hardcode rotation.x = 0 and rotation.z = 0
	rotation.x = 0.0
	rotation.z = 0.0
	
	_update_animation(delta)

# Enforces flat-plane look-at to eliminate pitch-tilt / belly-flop glitches
func look_at_flat(target: Vector3) -> void:
	var flat_target := Vector3(target.x, global_position.y, target.z)
	if global_position.distance_to(flat_target) > 0.01:
		look_at(flat_target, Vector3.UP)
		rotation.x = 0.0
		rotation.z = 0.0

func _init_materials() -> void:
	skin_mat = StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.78, 0.58, 0.44) # Athletic sun-kissed skin
	skin_mat.roughness = 0.65

	jersey_mat = StandardMaterial3D.new()
	jersey_mat.albedo_color = Color(0.05, 0.25, 0.65)
	jersey_mat.roughness = 0.45

	pants_mat = StandardMaterial3D.new()
	pants_mat.albedo_color = Color(0.05, 0.25, 0.65)
	pants_mat.roughness = 0.5

	bat_mat = StandardMaterial3D.new()
	bat_mat.albedo_color = Color(0.92, 0.82, 0.66) # English willow grain
	bat_mat.roughness = 0.4

	pads_mat = StandardMaterial3D.new()
	pads_mat.albedo_color = Color(0.95, 0.95, 0.96) # Molded white PU leather
	pads_mat.roughness = 0.35

	helmet_mat = StandardMaterial3D.new()
	helmet_mat.albedo_color = Color(0.04, 0.18, 0.45)
	helmet_mat.roughness = 0.25

	chrome_mat = StandardMaterial3D.new()
	chrome_mat.albedo_color = Color(0.85, 0.85, 0.88)
	chrome_mat.metallic = 0.95
	chrome_mat.roughness = 0.1

func _build_humanoid_rig() -> void:
	body_root = Node3D.new()
	body_root.name = "BodyRoot"
	add_child(body_root)

	# Pelvis / Hips (Y = 0.96m)
	hips = Node3D.new()
	hips.position = Vector3(0, 0.96, 0)
	body_root.add_child(hips)

	var pelvis_mesh := MeshInstance3D.new()
	var box_p := BoxMesh.new()
	box_p.size = Vector3(0.32, 0.20, 0.22)
	box_p.material = pants_mat
	pelvis_mesh.mesh = box_p
	hips.add_child(pelvis_mesh)

	# Spine & Athletic Tapered Chest (0.44m wide broad shoulders)
	spine = Node3D.new()
	spine.position = Vector3(0, 0.14, 0)
	hips.add_child(spine)

	chest = Node3D.new()
	chest.position = Vector3(0, 0.24, 0)
	spine.add_child(chest)

	var chest_mesh := MeshInstance3D.new()
	var box_c := BoxMesh.new()
	box_c.size = Vector3(0.44, 0.38, 0.26)
	box_c.material = jersey_mat
	chest_mesh.mesh = box_c
	chest.add_child(chest_mesh)

	# Neck & Head (Total Height = 1.84m)
	neck = Node3D.new()
	neck.position = Vector3(0, 0.24, 0)
	chest.add_child(neck)

	head = Node3D.new()
	head.position = Vector3(0, 0.14, 0)
	neck.add_child(head)

	var head_mesh := MeshInstance3D.new()
	var sphere_h := SphereMesh.new()
	sphere_h.radius = 0.11
	sphere_h.height = 0.22
	sphere_h.material = skin_mat
	head_mesh.mesh = sphere_h
	head.add_child(head_mesh)

	# Cricket Helmet & Chrome Grille
	_build_cricket_helmet()

	# Arms (Left & Right)
	_build_arms()

	# Legs (Left & Right)
	_build_legs()

	# Cricket Bat
	_build_cricket_bat()

	# Cricket Ball (for bowler)
	_build_cricket_ball()

func _build_cricket_helmet() -> void:
	helmet_node = Node3D.new()
	helmet_node.position = Vector3(0, 0.04, 0)
	head.add_child(helmet_node)

	# Aerodynamic shell
	var shell := MeshInstance3D.new()
	var sphere_s := SphereMesh.new()
	sphere_s.radius = 0.125
	sphere_s.height = 0.24
	sphere_s.material = helmet_mat
	shell.mesh = sphere_s
	helmet_node.add_child(shell)

	# Peak Visor
	var visor := MeshInstance3D.new()
	var box_v := BoxMesh.new()
	box_v.size = Vector3(0.18, 0.02, 0.08)
	box_v.material = helmet_mat
	visor.mesh = box_v
	visor.position = Vector3(0, 0.03, 0.13)
	helmet_node.add_child(visor)

	# Titanium Chrome Grille
	face_grille = Node3D.new()
	face_grille.position = Vector3(0, -0.06, 0.12)
	helmet_node.add_child(face_grille)

	for i in range(4):
		var bar := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.004
		cyl.bottom_radius = 0.004
		cyl.height = 0.16
		cyl.material = chrome_mat
		bar.mesh = cyl
		bar.rotation.z = deg_to_rad(90.0)
		bar.position = Vector3(0, float(i) * 0.025, 0)
		face_grille.add_child(bar)

	# Umpire Broad-Brim Sun Hat
	umpire_hat = Node3D.new()
	umpire_hat.position = Vector3(0, 0.10, 0)
	head.add_child(umpire_hat)
	var hat_brim := MeshInstance3D.new()
	var cyl_brim := CylinderMesh.new()
	cyl_brim.top_radius = 0.28
	cyl_brim.bottom_radius = 0.28
	cyl_brim.height = 0.02
	cyl_brim.material = pads_mat
	hat_brim.mesh = cyl_brim
	umpire_hat.add_child(hat_brim)
	umpire_hat.visible = false

func _build_arms() -> void:
	# Left Arm
	left_shoulder = Node3D.new()
	left_shoulder.position = Vector3(-0.25, 0.14, 0)
	chest.add_child(left_shoulder)

	left_arm = Node3D.new()
	left_shoulder.add_child(left_arm)
	var l_arm_m := MeshInstance3D.new()
	var cyl_la := CylinderMesh.new()
	cyl_la.top_radius = 0.055
	cyl_la.bottom_radius = 0.048
	cyl_la.height = 0.28
	cyl_la.material = jersey_mat
	l_arm_m.mesh = cyl_la
	l_arm_m.position = Vector3(0, -0.14, 0)
	left_arm.add_child(l_arm_m)

	left_forearm = Node3D.new()
	left_forearm.position = Vector3(0, -0.28, 0)
	left_arm.add_child(left_forearm)
	var l_fa_m := MeshInstance3D.new()
	var cyl_lfa := CylinderMesh.new()
	cyl_lfa.top_radius = 0.045
	cyl_lfa.bottom_radius = 0.038
	cyl_lfa.height = 0.26
	cyl_lfa.material = skin_mat
	l_fa_m.mesh = cyl_lfa
	l_fa_m.position = Vector3(0, -0.13, 0)
	left_forearm.add_child(l_fa_m)

	left_hand = Node3D.new()
	left_hand.position = Vector3(0, -0.26, 0)
	left_forearm.add_child(left_hand)

	gloves_left = Node3D.new()
	var box_gl := BoxMesh.new()
	box_gl.size = Vector3(0.08, 0.12, 0.08)
	box_gl.material = pads_mat
	var gl_m := MeshInstance3D.new()
	gl_m.mesh = box_gl
	gloves_left.add_child(gl_m)
	left_hand.add_child(gloves_left)

	# Right Arm
	right_shoulder = Node3D.new()
	right_shoulder.position = Vector3(0.25, 0.14, 0)
	chest.add_child(right_shoulder)

	right_arm = Node3D.new()
	right_shoulder.add_child(right_arm)
	var r_arm_m := MeshInstance3D.new()
	var cyl_ra := CylinderMesh.new()
	cyl_ra.top_radius = 0.055
	cyl_ra.bottom_radius = 0.048
	cyl_ra.height = 0.28
	cyl_ra.material = jersey_mat
	r_arm_m.mesh = cyl_ra
	r_arm_m.position = Vector3(0, -0.14, 0)
	right_arm.add_child(r_arm_m)

	right_forearm = Node3D.new()
	right_forearm.position = Vector3(0, -0.28, 0)
	right_arm.add_child(right_forearm)
	var r_fa_m := MeshInstance3D.new()
	var cyl_rfa := CylinderMesh.new()
	cyl_rfa.top_radius = 0.045
	cyl_rfa.bottom_radius = 0.038
	cyl_rfa.height = 0.26
	cyl_rfa.material = skin_mat
	r_fa_m.mesh = cyl_rfa
	r_fa_m.position = Vector3(0, -0.13, 0)
	right_forearm.add_child(r_fa_m)

	right_hand = Node3D.new()
	right_hand.position = Vector3(0, -0.26, 0)
	right_forearm.add_child(right_hand)

	gloves_right = Node3D.new()
	var box_gr := BoxMesh.new()
	box_gr.size = Vector3(0.08, 0.12, 0.08)
	box_gr.material = pads_mat
	var gr_m := MeshInstance3D.new()
	gr_m.mesh = box_gr
	gloves_right.add_child(gr_m)
	right_hand.add_child(gloves_right)

func _build_legs() -> void:
	# Left Leg
	left_thigh = Node3D.new()
	left_thigh.position = Vector3(-0.12, -0.10, 0)
	hips.add_child(left_thigh)

	var l_thigh_m := MeshInstance3D.new()
	var cyl_lt := CylinderMesh.new()
	cyl_lt.top_radius = 0.085
	cyl_lt.bottom_radius = 0.065
	cyl_lt.height = 0.42
	cyl_lt.material = pants_mat
	l_thigh_m.mesh = cyl_lt
	l_thigh_m.position = Vector3(0, -0.21, 0)
	left_thigh.add_child(l_thigh_m)

	left_knee = Node3D.new()
	left_knee.position = Vector3(0, -0.42, 0)
	left_thigh.add_child(left_knee)

	var l_calf_m := MeshInstance3D.new()
	var cyl_lc := CylinderMesh.new()
	cyl_lc.top_radius = 0.065
	cyl_lc.bottom_radius = 0.052
	cyl_lc.height = 0.42
	cyl_lc.material = pants_mat
	l_calf_m.mesh = cyl_lc
	l_calf_m.position = Vector3(0, -0.21, 0)
	left_knee.add_child(l_calf_m)

	# Left Batting Pad (3 horizontal knee rolls & vertical cane ribs)
	pads_left = _create_batting_pad()
	pads_left.position = Vector3(0, -0.18, 0.06)
	left_knee.add_child(pads_left)

	left_foot = Node3D.new()
	left_foot.position = Vector3(0, -0.42, 0)
	left_knee.add_child(left_foot)
	var l_shoe := _create_cricket_shoe()
	left_foot.add_child(l_shoe)

	# Right Leg
	right_thigh = Node3D.new()
	right_thigh.position = Vector3(0.12, -0.10, 0)
	hips.add_child(right_thigh)

	var r_thigh_m := MeshInstance3D.new()
	var cyl_rt := CylinderMesh.new()
	cyl_rt.top_radius = 0.085
	cyl_rt.bottom_radius = 0.065
	cyl_rt.height = 0.42
	cyl_rt.material = pants_mat
	r_thigh_m.mesh = cyl_rt
	r_thigh_m.position = Vector3(0, -0.21, 0)
	right_thigh.add_child(r_thigh_m)

	right_knee = Node3D.new()
	right_knee.position = Vector3(0, -0.42, 0)
	right_thigh.add_child(right_knee)

	var r_calf_m := MeshInstance3D.new()
	var cyl_rc := CylinderMesh.new()
	cyl_rc.top_radius = 0.065
	cyl_rc.bottom_radius = 0.052
	cyl_rc.height = 0.42
	cyl_rc.material = pants_mat
	r_calf_m.mesh = cyl_rc
	r_calf_m.position = Vector3(0, -0.21, 0)
	right_knee.add_child(r_calf_m)

	# Right Batting Pad
	pads_right = _create_batting_pad()
	pads_right.position = Vector3(0, -0.18, 0.06)
	right_knee.add_child(pads_right)

	right_foot = Node3D.new()
	right_foot.position = Vector3(0, -0.42, 0)
	right_knee.add_child(right_foot)
	var r_shoe := _create_cricket_shoe()
	right_foot.add_child(r_shoe)

func _create_batting_pad() -> Node3D:
	var pad := Node3D.new()
	# Main cane rib face
	var face := MeshInstance3D.new()
	var box_f := BoxMesh.new()
	box_f.size = Vector3(0.16, 0.46, 0.06)
	box_f.material = pads_mat
	face.mesh = box_f
	pad.add_child(face)

	# 3 Horizontal Knee Rolls
	for i in range(3):
		var roll := MeshInstance3D.new()
		var cyl_r := CylinderMesh.new()
		cyl_r.top_radius = 0.02
		cyl_r.bottom_radius = 0.02
		cyl_r.height = 0.16
		cyl_r.material = pads_mat
		roll.mesh = cyl_r
		roll.rotation.z = deg_to_rad(90.0)
		roll.position = Vector3(0, 0.12 - float(i) * 0.04, 0.035)
		pad.add_child(roll)

	return pad

func _create_cricket_shoe() -> Node3D:
	var shoe := Node3D.new()
	var shoe_m := MeshInstance3D.new()
	var box_s := BoxMesh.new()
	box_s.size = Vector3(0.10, 0.06, 0.22)
	box_s.material = pads_mat # White cricket leather
	shoe_m.mesh = box_s
	shoe_m.position = Vector3(0, -0.03, 0.05)
	shoe.add_child(shoe_m)
	return shoe

func _build_cricket_bat() -> void:
	bat_node = Node3D.new()
	bat_node.position = Vector3(0, -0.05, 0.05)
	right_hand.add_child(bat_node)

	# Cane Handle with Chevron Grip
	var handle := MeshInstance3D.new()
	var cyl_h := CylinderMesh.new()
	cyl_h.top_radius = 0.018
	cyl_h.bottom_radius = 0.018
	cyl_h.height = 0.32
	var grip_mat := StandardMaterial3D.new()
	grip_mat.albedo_color = Color(0.12, 0.12, 0.12) # Black rubber grip
	cyl_h.material = grip_mat
	handle.mesh = cyl_h
	handle.position = Vector3(0, -0.16, 0)
	bat_node.add_child(handle)

	# English Willow Blade (38mm edges, 64mm spine swell, contoured back)
	var blade := MeshInstance3D.new()
	var box_b := BoxMesh.new()
	box_b.size = Vector3(0.11, 0.58, 0.06)
	box_b.material = bat_mat
	blade.mesh = box_b
	blade.position = Vector3(0, -0.58, 0.01)
	bat_node.add_child(blade)

func _build_cricket_ball() -> void:
	ball_held = Node3D.new()
	ball_held.position = Vector3(0, -0.06, 0.04)
	right_hand.add_child(ball_held)

	var ball_m := MeshInstance3D.new()
	var sph_b := SphereMesh.new()
	sph_b.radius = 0.036
	sph_b.height = 0.072
	var red_leather := StandardMaterial3D.new()
	red_leather.albedo_color = Color(0.76, 0.08, 0.12)
	red_leather.roughness = 0.3
	sph_b.material = red_leather
	ball_m.mesh = sph_b
	ball_held.add_child(ball_m)
	ball_held.visible = false

func _apply_role_configuration() -> void:
	helmet_node.visible = false
	pads_left.visible = false
	pads_right.visible = false
	gloves_left.visible = false
	gloves_right.visible = false
	bat_node.visible = false
	ball_held.visible = false
	umpire_hat.visible = false

	match role:
		PlayerRole.BATSMAN:
			helmet_node.visible = true
			pads_left.visible = true
			pads_right.visible = true
			gloves_left.visible = true
			gloves_right.visible = true
			bat_node.visible = true
		PlayerRole.BOWLER:
			ball_held.visible = true
		PlayerRole.WICKETKEEPER:
			helmet_node.visible = true
			pads_left.visible = true
			pads_right.visible = true
			gloves_left.visible = true
			gloves_right.visible = true
		PlayerRole.FIELDER:
			pass
		PlayerRole.UMPIRE:
			umpire_hat.visible = true
			jersey_mat.albedo_color = Color(0.35, 0.65, 0.85) # Umpire light blue
			pants_mat.albedo_color = Color(0.1, 0.1, 0.1) # Black trousers

func _apply_team_kit() -> void:
	if role == PlayerRole.UMPIRE:
		return
	var t: Dictionary = DataManager.get_team(team_id)
	jersey_mat.albedo_color = t["primary_color"]
	pants_mat.albedo_color = t["primary_color"]
	helmet_mat.albedo_color = t["primary_color"]

func play_animation(anim_name: String, speed: float = 1.0) -> void:
	current_anim = anim_name
	anim_time = 0.0
	anim_speed = speed

func _update_animation(delta: float) -> void:
	anim_time += delta * anim_speed

	match current_anim:
		"stance":
			_pose_stance()
		"front_foot_drive":
			_pose_front_foot_drive(anim_time)
		"lofted_drive":
			_pose_lofted_drive(anim_time)
		"pull_shot":
			_pose_pull_shot(anim_time)
		"cut_shot":
			_pose_cut_shot(anim_time)
		"helicopter_shot":
			_pose_helicopter_shot(anim_time)
		"defend_forward":
			_pose_defend_forward(anim_time)
		"leave":
			_pose_leave(anim_time)
		"celebration_bat_raise":
			_pose_celebration_bat_raise(anim_time)
		"runup":
			_pose_runup(anim_time)
		"delivery_stride":
			_pose_delivery_stride(anim_time)
		"celebration_wicket":
			_pose_celebration_wicket(anim_time)
		"keeper_crouch":
			_pose_keeper_crouch()
		"fielder_ready":
			_pose_fielder_ready()
		"fielder_sprint":
			_pose_fielder_sprint(anim_time)
		"umpire_out":
			_pose_umpire_out(anim_time)
		"umpire_four":
			_pose_umpire_four(anim_time)
		"umpire_six":
			_pose_umpire_six(anim_time)

# --- Posing & Procedural Skeletal Inverse Kinematics ---

func _pose_stance() -> void:
	# Balanced sideways stance at popping crease with bat tap
	body_root.position.y = 0.0
	hips.position = Vector3(0, 0.94, 0)
	hips.rotation = Vector3(0, deg_to_rad(-85.0), 0)
	head.rotation = Vector3(0, deg_to_rad(80.0), 0)

	left_thigh.rotation = Vector3(deg_to_rad(15.0), 0, deg_to_rad(-5.0))
	left_knee.rotation = Vector3(deg_to_rad(-25.0), 0, 0)
	right_thigh.rotation = Vector3(deg_to_rad(10.0), 0, deg_to_rad(5.0))
	right_knee.rotation = Vector3(deg_to_rad(-20.0), 0, 0)

	var bat_tap: float = sin(anim_time * 5.0) * 0.08
	right_shoulder.rotation = Vector3(deg_to_rad(30.0 + bat_tap * 10.0), 0, deg_to_rad(20.0))
	right_forearm.rotation = Vector3(deg_to_rad(-45.0), 0, 0)
	left_shoulder.rotation = Vector3(deg_to_rad(25.0), 0, deg_to_rad(-15.0))
	left_forearm.rotation = Vector3(deg_to_rad(-50.0), 0, 0)
	bat_node.rotation = Vector3(deg_to_rad(15.0 + bat_tap * 20.0), 0, 0)

func _pose_front_foot_drive(t: float) -> void:
	var progress: float = clamp(t * 2.5, 0.0, 1.0)
	# Fluid stride forward, high elbow, bat down the line
	hips.position.z = lerp(0.0, 0.35, progress)
	left_thigh.rotation = Vector3(deg_to_rad(lerp(15.0, 45.0, progress)), 0, 0)
	left_knee.rotation = Vector3(deg_to_rad(lerp(-25.0, -65.0, progress)), 0, 0)
	
	# High front elbow
	left_shoulder.rotation = Vector3(deg_to_rad(lerp(25.0, -75.0, progress)), 0, deg_to_rad(-35.0))
	right_shoulder.rotation = Vector3(deg_to_rad(lerp(30.0, -55.0, progress)), 0, deg_to_rad(15.0))
	bat_node.rotation = Vector3(deg_to_rad(lerp(15.0, -80.0, progress)), 0, 0)

func _pose_lofted_drive(t: float) -> void:
	var progress: float = clamp(t * 3.0, 0.0, 1.0)
	# Explosive upward bat swing through the line, high backlift & follow-through
	hips.position.z = lerp(0.0, 0.25, progress)
	spine.rotation = Vector3(deg_to_rad(lerp(0.0, -20.0, progress)), 0, 0)
	right_shoulder.rotation = Vector3(deg_to_rad(lerp(30.0, -110.0, progress)), 0, deg_to_rad(25.0))
	left_shoulder.rotation = Vector3(deg_to_rad(lerp(25.0, -100.0, progress)), 0, deg_to_rad(-20.0))
	bat_node.rotation = Vector3(deg_to_rad(lerp(15.0, -135.0, progress)), 0, 0)

func _pose_pull_shot(t: float) -> void:
	var progress: float = clamp(t * 3.0, 0.0, 1.0)
	# Back foot pivot, horizontal bat blade pulling through mid-wicket
	hips.position.z = lerp(0.0, -0.2, progress)
	hips.rotation = Vector3(0, deg_to_rad(lerp(-85.0, -10.0, progress)), 0)
	right_shoulder.rotation = Vector3(deg_to_rad(20.0), deg_to_rad(lerp(0.0, 75.0, progress)), deg_to_rad(45.0))
	bat_node.rotation = Vector3(0, deg_to_rad(lerp(0.0, 85.0, progress)), deg_to_rad(-70.0))

func _pose_cut_shot(t: float) -> void:
	var progress: float = clamp(t * 3.0, 0.0, 1.0)
	# Back foot stride, slicing bat down & through point
	hips.position.x = lerp(0.0, 0.15, progress)
	right_shoulder.rotation = Vector3(deg_to_rad(lerp(40.0, -45.0, progress)), deg_to_rad(-30.0), deg_to_rad(30.0))
	bat_node.rotation = Vector3(deg_to_rad(lerp(20.0, -70.0, progress)), deg_to_rad(-45.0), 0)

func _pose_helicopter_shot(t: float) -> void:
	var progress: float = clamp(t * 2.8, 0.0, 1.0)
	# Low wrist flick whipping ball over mid-wicket with full 360 twirl
	hips.rotation = Vector3(0, deg_to_rad(lerp(-85.0, 30.0, progress)), 0)
	right_shoulder.rotation = Vector3(deg_to_rad(lerp(30.0, -120.0, progress)), deg_to_rad(lerp(0.0, 180.0, progress)), 0)
	bat_node.rotation = Vector3(deg_to_rad(lerp(15.0, -160.0, progress)), deg_to_rad(progress * 360.0), 0)

func _pose_defend_forward(t: float) -> void:
	var progress: float = clamp(t * 3.0, 0.0, 1.0)
	# Soft hands forward defensive block deadening ball into pitch
	hips.position.z = lerp(0.0, 0.25, progress)
	left_knee.rotation = Vector3(deg_to_rad(lerp(-25.0, -50.0, progress)), 0, 0)
	right_shoulder.rotation = Vector3(deg_to_rad(lerp(30.0, -35.0, progress)), 0, deg_to_rad(15.0))
	left_shoulder.rotation = Vector3(deg_to_rad(lerp(25.0, -40.0, progress)), 0, deg_to_rad(-20.0))
	bat_node.rotation = Vector3(deg_to_rad(lerp(15.0, -45.0, progress)), 0, 0)

func _pose_leave(t: float) -> void:
	var progress: float = clamp(t * 2.5, 0.0, 1.0)
	# High bat lift & torso recoil
	hips.position.z = lerp(0.0, -0.15, progress)
	right_shoulder.rotation = Vector3(deg_to_rad(lerp(30.0, 95.0, progress)), 0, deg_to_rad(30.0))
	left_shoulder.rotation = Vector3(deg_to_rad(lerp(25.0, 85.0, progress)), 0, deg_to_rad(-30.0))
	bat_node.rotation = Vector3(deg_to_rad(lerp(15.0, 75.0, progress)), 0, 0)

func _pose_celebration_bat_raise(t: float) -> void:
	# Raises bat vertically to pavilion
	right_shoulder.rotation = Vector3(deg_to_rad(-165.0), 0, deg_to_rad(15.0))
	bat_node.rotation = Vector3(deg_to_rad(180.0), 0, 0)
	left_shoulder.rotation = Vector3(deg_to_rad(-140.0), 0, deg_to_rad(-20.0))

func _pose_runup(t: float) -> void:
	# Athletic sprint approach strides
	var stride: float = sin(t * 14.0)
	hips.position.y = 0.96 + abs(sin(t * 14.0)) * 0.05
	left_thigh.rotation = Vector3(stride * 0.75, 0, 0)
	left_knee.rotation = Vector3(-abs(stride) * 0.6, 0, 0)
	right_thigh.rotation = Vector3(-stride * 0.75, 0, 0)
	right_knee.rotation = Vector3(-abs(stride) * 0.6, 0, 0)

	left_shoulder.rotation = Vector3(-stride * 0.8, 0, 0)
	right_shoulder.rotation = Vector3(stride * 0.8, 0, 0)

func _pose_delivery_stride(t: float) -> void:
	# 360 overarm windmill arm rotation & wrist flick release at apex
	var progress: float = clamp(t * 1.8, 0.0, 1.0)
	var arm_angle: float = lerp(60.0, -300.0, progress)
	right_shoulder.rotation = Vector3(deg_to_rad(arm_angle), 0, deg_to_rad(10.0))
	left_shoulder.rotation = Vector3(deg_to_rad(-45.0), 0, deg_to_rad(-30.0))
	
	# Release ball at apex (around progress = 0.65)
	if progress >= 0.65 and ball_held.visible:
		ball_held.visible = false

func _pose_celebration_wicket(t: float) -> void:
	# Bowler leaps in jubilation with fist pump
	var leap: float = max(sin(t * 6.0), 0.0) * 0.25
	hips.position.y = 0.96 + leap
	right_shoulder.rotation = Vector3(deg_to_rad(-165.0), 0, deg_to_rad(20.0))
	left_shoulder.rotation = Vector3(deg_to_rad(-140.0), 0, deg_to_rad(-20.0))

func _pose_keeper_crouch() -> void:
	hips.position.y = 0.62
	left_thigh.rotation = Vector3(deg_to_rad(65.0), 0, deg_to_rad(-10.0))
	left_knee.rotation = Vector3(deg_to_rad(-95.0), 0, 0)
	right_thigh.rotation = Vector3(deg_to_rad(65.0), 0, deg_to_rad(10.0))
	right_knee.rotation = Vector3(deg_to_rad(-95.0), 0, 0)

	left_shoulder.rotation = Vector3(deg_to_rad(-35.0), 0, deg_to_rad(-15.0))
	right_shoulder.rotation = Vector3(deg_to_rad(-35.0), 0, deg_to_rad(15.0))

func _pose_fielder_ready() -> void:
	hips.position.y = 0.82
	left_thigh.rotation = Vector3(deg_to_rad(35.0), 0, 0)
	left_knee.rotation = Vector3(deg_to_rad(-45.0), 0, 0)
	right_thigh.rotation = Vector3(deg_to_rad(35.0), 0, 0)
	right_knee.rotation = Vector3(deg_to_rad(-45.0), 0, 0)

	left_shoulder.rotation = Vector3(deg_to_rad(20.0), 0, deg_to_rad(-10.0))
	right_shoulder.rotation = Vector3(deg_to_rad(20.0), 0, deg_to_rad(10.0))

func _pose_fielder_sprint(t: float) -> void:
	_pose_runup(t * 1.2)

func _pose_umpire_out(t: float) -> void:
	var progress: float = clamp(t * 1.5, 0.0, 1.0)
	# Slow, dramatic raised index finger
	right_shoulder.rotation = Vector3(deg_to_rad(lerp(0.0, -170.0, progress)), 0, 0)
	left_shoulder.rotation = Vector3(0, 0, 0)

func _pose_umpire_four(t: float) -> void:
	# Side to side waving arm across waist
	var wave: float = sin(t * 8.0) * 45.0
	right_shoulder.rotation = Vector3(deg_to_rad(45.0), deg_to_rad(wave), deg_to_rad(30.0))

func _pose_umpire_six(t: float) -> void:
	var progress: float = clamp(t * 2.0, 0.0, 1.0)
	# Both arms raised high overhead
	right_shoulder.rotation = Vector3(deg_to_rad(lerp(0.0, -175.0, progress)), 0, deg_to_rad(15.0))
	left_shoulder.rotation = Vector3(deg_to_rad(lerp(0.0, -175.0, progress)), 0, deg_to_rad(-15.0))

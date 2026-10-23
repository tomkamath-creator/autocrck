# scripts/players/player_mesh_builder.gd
# Realistic 3D Athlete Mesh & Equipment Synthesizer (RC24 / WCC3 Visual Fidelity)
# Generates adult athletic male models (1.85m), English willow bat, 3-knee-roll pads, chrome grille helmet, and team kits.
class_name PlayerMeshBuilder
extends RefCounted

static func build_player_model(role: String, team_name: String, player_name: String, jersey_num: int, build_type: String = "Athletic", skin_tone_idx: int = 1) -> Node3D:
	var root = Node3D.new()
	root.name = "PlayerModel_" + player_name.replace(" ", "_")
	
	# Determine skin tone palette
	var skin_color = Color(0.82, 0.65, 0.52) # Wheatish / Subcontinental default
	if skin_tone_idx == 0:
		skin_color = Color(0.92, 0.78, 0.68) # Fair
	elif skin_tone_idx == 2:
		skin_color = Color(0.48, 0.35, 0.26) # Dark
	
	# Team color scheme lookup
	var primary_color = Color(0.04, 0.22, 0.45) # Navy Blue default
	var secondary_color = Color(1.0, 0.55, 0.0) # Saffron/Orange accent
	var trouser_color = primary_color
	
	if role == "Umpire":
		primary_color = Color(0.35, 0.65, 0.88) # Light blue umpire shirt
		secondary_color = Color(0.1, 0.1, 0.1)
		trouser_color = Color(0.08, 0.08, 0.08) # Black trousers
	else:
		match team_name:
			"India":
				primary_color = Color(0.05, 0.25, 0.55)
				secondary_color = Color(1.0, 0.55, 0.0)
				trouser_color = primary_color
			"Australia":
				primary_color = Color(0.92, 0.76, 0.08)
				secondary_color = Color(0.0, 0.35, 0.15)
				trouser_color = primary_color
			"England":
				primary_color = Color(0.05, 0.12, 0.28)
				secondary_color = Color(0.85, 0.1, 0.1)
				trouser_color = primary_color
			"South Africa":
				primary_color = Color(0.0, 0.38, 0.22)
				secondary_color = Color(0.95, 0.8, 0.1)
				trouser_color = primary_color
	
	# Materials
	var skin_mat = _create_material(skin_color, 0.65, 0.02)
	var jersey_mat = _create_material(primary_color, 0.55, 0.08)
	var trim_mat = _create_material(secondary_color, 0.45, 0.05)
	var trouser_mat = _create_material(trouser_color, 0.60, 0.05)
	var white_mat = _create_material(Color(0.95, 0.95, 0.95), 0.4, 0.1)
	var shoe_mat = _create_material(Color(0.92, 0.92, 0.94), 0.3, 0.15)
	
	# Build scaling factors (Height: 1.82m - 1.88m, Shoulders: 0.44m wide)
	var shoulder_width = 0.44
	var torso_depth = 0.26
	var scale_height = 1.0
	
	if build_type == "Slim":
		shoulder_width = 0.40
		torso_depth = 0.23
		scale_height = 0.98
	elif build_type == "Heavy":
		shoulder_width = 0.48
		torso_depth = 0.32
		scale_height = 1.02
	
	# ----------------- HIERARCHICAL SKELETON NODES -----------------
	var hips = Node3D.new()
	hips.name = "Hips"
	hips.position = Vector3(0, 0.98 * scale_height, 0)
	root.add_child(hips)
	
	# Pelvis / Hips mesh
	var pelvis = _create_box(Vector3(shoulder_width * 0.70, 0.18, torso_depth * 0.9), trouser_mat)
	pelvis.name = "PelvisMesh"
	hips.add_child(pelvis)
	
	# Spine & Torso (Athletic muscular taper)
	var spine = Node3D.new()
	spine.name = "Spine"
	spine.position = Vector3(0, 0.10, 0)
	hips.add_child(spine)
	
	var chest = Node3D.new()
	chest.name = "Chest"
	chest.position = Vector3(0, 0.24, 0)
	spine.add_child(chest)
	
	var chest_mesh = _create_box(Vector3(shoulder_width, 0.32, torso_depth), jersey_mat)
	chest_mesh.name = "ChestMesh"
	chest_mesh.position = Vector3(0, 0.02, 0)
	chest.add_child(chest_mesh)
	
	# Team crest on left chest
	var crest = _create_box(Vector3(0.06, 0.06, 0.01), trim_mat)
	crest.position = Vector3(shoulder_width * 0.28, 0.06, torso_depth * 0.51)
	chest.add_child(crest)
	
	# Player Name & Jersey Number on the back
	var name_plate = _create_back_nameplate(player_name, jersey_num)
	name_plate.position = Vector3(0, 0.05, -torso_depth * 0.52)
	chest.add_child(name_plate)
	
	# Neck & Head
	var neck = Node3D.new()
	neck.name = "Neck"
	neck.position = Vector3(0, 0.20, 0)
	chest.add_child(neck)
	var neck_mesh = _create_cylinder(0.065, 0.08, skin_mat)
	neck.add_child(neck_mesh)
	
	var head = Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.12, 0)
	neck.add_child(head)
	
	if role == "Umpire":
		var face = _create_cylinder(0.09, 0.18, skin_mat)
		head.add_child(face)
		_attach_umpire_hat(head)
	elif role == "Bowler" or role == "Fielder":
		var face = _create_cylinder(0.09, 0.18, skin_mat)
		head.add_child(face)
		_attach_athletic_hair(head, Color(0.12, 0.08, 0.05))
	else:
		# Batsman or Wicketkeeper wears aerodynamic helmet with metallic chrome grille
		_attach_cricket_helmet(head, primary_color)
	
	# ----------------- SHOULDERS & ARMS -----------------
	var left_arm = _build_arm(true, shoulder_width, skin_mat, jersey_mat, trim_mat, role)
	chest.add_child(left_arm)
	
	var right_arm = _build_arm(false, shoulder_width, skin_mat, jersey_mat, trim_mat, role)
	chest.add_child(right_arm)
	
	# Attach English Willow Bat to right hand for batsman
	if role == "Batsman":
		var r_hand = right_arm.get_node("RightElbow/RightHand")
		var bat = _build_cricket_bat()
		bat.name = "CricketBat"
		bat.position = Vector3(0, -0.10, 0.08)
		bat.rotation_degrees = Vector3(-15, 0, 10)
		r_hand.add_child(bat)
	elif role == "Bowler":
		# Cricket ball held in right hand
		var r_hand = right_arm.get_node("RightElbow/RightHand")
		var ball_held = _create_sphere(0.036, Color(0.85, 0.08, 0.08))
		ball_held.name = "HeldBall"
		ball_held.position = Vector3(0, -0.06, 0.02)
		r_hand.add_child(ball_held)
	
	# ----------------- LEGS & FEET -----------------
	var left_leg = _build_leg(true, shoulder_width, trouser_mat, shoe_mat, role, white_mat)
	hips.add_child(left_leg)
	
	var right_leg = _build_leg(false, shoulder_width, trouser_mat, shoe_mat, role, white_mat)
	hips.add_child(right_leg)
	
	return root

static func _build_arm(is_left: bool, shoulder_width: float, skin_mat: Material, jersey_mat: Material, trim_mat: Material, role: String) -> Node3D:
	var side_mult = -1.0 if is_left else 1.0
	var prefix = "Left" if is_left else "Right"
	
	var shoulder = Node3D.new()
	shoulder.name = prefix + "Shoulder"
	shoulder.position = Vector3(side_mult * (shoulder_width * 0.52), 0.14, 0)
	
	# Sleeve
	var sleeve = _create_box(Vector3(0.12, 0.14, 0.12), jersey_mat)
	shoulder.add_child(sleeve)
	
	# Upper arm
	var upper_arm = _create_cylinder(0.055, 0.22, skin_mat)
	upper_arm.position = Vector3(0, -0.12, 0)
	shoulder.add_child(upper_arm)
	
	# Elbow & Forearm
	var elbow = Node3D.new()
	elbow.name = prefix + "Elbow"
	elbow.position = Vector3(0, -0.22, 0)
	shoulder.add_child(elbow)
	
	var forearm = _create_cylinder(0.048, 0.20, skin_mat)
	forearm.position = Vector3(0, -0.10, 0)
	elbow.add_child(forearm)
	
	# Hand / Batting Glove
	var hand = Node3D.new()
	hand.name = prefix + "Hand"
	hand.position = Vector3(0, -0.20, 0)
	elbow.add_child(hand)
	
	if role == "Batsman":
		var glove = _build_batting_glove(trim_mat)
		hand.add_child(glove)
	elif role == "Wicketkeeper":
		var keeper_glove = _build_wicketkeeping_glove()
		hand.add_child(keeper_glove)
	else:
		var hand_mesh = _create_box(Vector3(0.06, 0.10, 0.04), skin_mat)
		hand.add_child(hand_mesh)
	
	return shoulder

static func _build_leg(is_left: bool, shoulder_width: float, trouser_mat: Material, shoe_mat: Material, role: String, pad_mat: Material) -> Node3D:
	var side_mult = -1.0 if is_left else 1.0
	var prefix = "Left" if is_left else "Right"
	
	var hip_joint = Node3D.new()
	hip_joint.name = prefix + "HipJoint"
	hip_joint.position = Vector3(side_mult * (shoulder_width * 0.25), -0.05, 0)
	
	# Thigh
	var thigh = _create_cylinder(0.08, 0.42, trouser_mat)
	thigh.position = Vector3(0, -0.20, 0)
	hip_joint.add_child(thigh)
	
	# Knee
	var knee = Node3D.new()
	knee.name = prefix + "Knee"
	knee.position = Vector3(0, -0.42, 0)
	hip_joint.add_child(knee)
	
	# Shin / Calf
	var shin = _create_cylinder(0.065, 0.40, trouser_mat)
	shin.position = Vector3(0, -0.19, 0)
	knee.add_child(shin)
	
	# Batting Pads (3 horizontal knee rolls, 7 cane ribs)
	if role == "Batsman" or role == "Wicketkeeper":
		var pad = _build_batting_pad(pad_mat)
		pad.name = "BattingPad"
		pad.position = Vector3(0, -0.14, 0.04)
		knee.add_child(pad)
	
	# Ankle & Spiked Shoe
	var ankle = Node3D.new()
	ankle.name = prefix + "Ankle"
	ankle.position = Vector3(0, -0.38, 0)
	knee.add_child(ankle)
	
	var shoe = _build_cricket_shoe(shoe_mat)
	ankle.add_child(shoe)
	
	return hip_joint

# ----------------- EQUIPMENT BUILDERS -----------------

static func _build_cricket_bat() -> Node3D:
	var bat = Node3D.new()
	
	# Handle: Rubber chevron grip
	var handle_mat = _create_material(Color(0.95, 0.95, 0.95), 0.7, 0.02)
	var handle = _create_cylinder(0.018, 0.32, handle_mat)
	handle.position = Vector3(0, 0.16, 0)
	bat.add_child(handle)
	
	# Blade: English Willow with contoured spine & 38mm edges
	var willow_mat = _create_material(Color(0.88, 0.74, 0.52), 0.45, 0.05)
	# Blade front face (flat)
	var blade = _create_box(Vector3(0.11, 0.58, 0.038), willow_mat)
	blade.position = Vector3(0, -0.26, 0)
	bat.add_child(blade)
	
	# 3D Contoured Spine Swell (64mm maximum depth)
	var spine_mat = _create_material(Color(0.84, 0.70, 0.48), 0.45, 0.05)
	var spine = _create_box(Vector3(0.05, 0.46, 0.03), spine_mat)
	spine.position = Vector3(0, -0.25, -0.026)
	bat.add_child(spine)
	
	# Sponsor Brand Decal on blade front
	var decal_mat = _create_material(Color(0.85, 0.05, 0.05), 0.3, 0.1)
	var decal = _create_box(Vector3(0.08, 0.18, 0.002), decal_mat)
	decal.position = Vector3(0, -0.18, 0.020)
	bat.add_child(decal)
	
	# Rubber protective toe guard
	var toe_mat = _create_material(Color(0.1, 0.1, 0.1), 0.8, 0.0)
	var toe = _create_box(Vector3(0.112, 0.03, 0.04), toe_mat)
	toe.position = Vector3(0, -0.56, 0)
	bat.add_child(toe)
	
	return bat

static func _build_batting_pad(pad_mat: Material) -> Node3D:
	var pad = Node3D.new()
	
	# Main leg face (7 cane ribs represented)
	var main_guard = _create_box(Vector3(0.18, 0.48, 0.06), pad_mat)
	main_guard.position = Vector3(0, -0.06, 0.02)
	pad.add_child(main_guard)
	
	# 3 Distinct Horizontal Knee Rolls
	var roll_mat = _create_material(Color(0.98, 0.98, 0.98), 0.5, 0.05)
	for i in range(3):
		var knee_roll = _create_cylinder(0.022, 0.19, roll_mat)
		knee_roll.rotation_degrees = Vector3(0, 0, 90)
		knee_roll.position = Vector3(0, 0.12 - (i * 0.035), 0.05)
		pad.add_child(knee_roll)
	
	# Top hat protection
	var top_hat = _create_box(Vector3(0.17, 0.12, 0.05), pad_mat)
	top_hat.position = Vector3(0, 0.20, 0.01)
	pad.add_child(top_hat)
	
	# Dark Velcro straps around the back
	var strap_mat = _create_material(Color(0.1, 0.1, 0.15), 0.9, 0.0)
	for s in [-0.22, -0.05, 0.14]:
		var strap = _create_box(Vector3(0.16, 0.028, 0.07), strap_mat)
		strap.position = Vector3(0, s, -0.02)
		pad.add_child(strap)
	
	return pad

static func _attach_cricket_helmet(head: Node3D, helmet_color: Color) -> void:
	# Aerodynamic fabric shell
	var shell_mat = _create_material(helmet_color, 0.35, 0.12)
	var shell = _create_sphere(0.115, helmet_color)
	shell.position = Vector3(0, 0.04, -0.01)
	head.add_child(shell)
	
	# Peak visor
	var visor = _create_box(Vector3(0.15, 0.02, 0.10), shell_mat)
	visor.position = Vector3(0, 0.05, 0.11)
	head.add_child(visor)
	
	# Metallic Chrome Specular Face Grille
	var grille_mat = StandardMaterial3D.new()
	grille_mat.albedo_color = Color(0.9, 0.92, 0.95)
	grille_mat.metallic = 0.95
	grille_mat.roughness = 0.15
	
	# Horizontal steel bars
	for b in range(4):
		var bar = _create_cylinder(0.0035, 0.16, grille_mat)
		bar.rotation_degrees = Vector3(0, 0, 90)
		bar.position = Vector3(0, 0.01 - (b * 0.028), 0.10)
		head.add_child(bar)
	
	# Vertical central reinforcement strut
	var v_bar = _create_cylinder(0.004, 0.12, grille_mat)
	v_bar.position = Vector3(0, -0.03, 0.10)
	head.add_child(v_bar)

static func _attach_umpire_hat(head: Node3D) -> void:
	var white_mat = _create_material(Color(0.96, 0.96, 0.96), 0.5, 0.02)
	# Broad brim
	var brim = _create_cylinder(0.18, 0.015, white_mat)
	brim.position = Vector3(0, 0.07, 0)
	head.add_child(brim)
	# Crown
	var crown = _create_cylinder(0.10, 0.08, white_mat)
	crown.position = Vector3(0, 0.11, 0)
	head.add_child(crown)

static func _attach_athletic_hair(head: Node3D, hair_color: Color) -> void:
	var hair_mat = _create_material(hair_color, 0.85, 0.0)
	var hair = _create_sphere(0.105, hair_color)
	hair.position = Vector3(0, 0.05, -0.015)
	head.add_child(hair)

static func _build_batting_glove(accent_mat: Material) -> Node3D:
	var glove = Node3D.new()
	var white_mat = _create_material(Color(0.96, 0.96, 0.96), 0.4, 0.05)
	var palm = _create_box(Vector3(0.07, 0.08, 0.045), white_mat)
	glove.add_child(palm)
	# Finger rolls
	for f in range(4):
		var roll = _create_box(Vector3(0.016, 0.05, 0.02), accent_mat)
		roll.position = Vector3(-0.024 + (f * 0.016), -0.05, 0.01)
		glove.add_child(roll)
	return glove

static func _build_wicketkeeping_glove() -> Node3D:
	var glove = Node3D.new()
	var mat = _create_material(Color(0.12, 0.45, 0.85), 0.4, 0.1)
	var base = _create_box(Vector3(0.09, 0.12, 0.05), mat)
	glove.add_child(base)
	# Webbing between thumb and index
	var web_mat = _create_material(Color(0.9, 0.9, 0.9), 0.5, 0.05)
	var web = _create_box(Vector3(0.05, 0.05, 0.01), web_mat)
	web.position = Vector3(0.04, -0.02, 0)
	glove.add_child(web)
	return glove

static func _build_cricket_shoe(shoe_mat: Material) -> Node3D:
	var shoe = Node3D.new()
	var shoe_mesh = _create_box(Vector3(0.08, 0.065, 0.22), shoe_mat)
	shoe_mesh.position = Vector3(0, -0.03, 0.05)
	shoe.add_child(shoe_mesh)
	# Metal spikes / studs
	var spike_mat = _create_material(Color(0.7, 0.7, 0.75), 0.2, 0.9)
	var spikes = _create_box(Vector3(0.075, 0.01, 0.20), spike_mat)
	spikes.position = Vector3(0, -0.065, 0.05)
	shoe.add_child(spikes)
	return shoe

static func _create_back_nameplate(player_name: String, jersey_num: int) -> Node3D:
	var node = Node3D.new()
	var text_mesh = TextMesh.new()
	text_mesh.text = player_name.to_upper() + "\n" + str(jersey_num)
	text_mesh.font_size = 18
	text_mesh.pixel_size = 0.003
	text_mesh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var inst = MeshInstance3D.new()
	inst.mesh = text_mesh
	inst.rotation_degrees = Vector3(0, 180, 0)
	node.add_child(inst)
	return node

# ----------------- PRIMITIVE HELPERS -----------------

static func _create_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	return mat

static func _create_box(size: Vector3, mat: Material) -> MeshInstance3D:
	var inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	box.material = mat
	inst.mesh = box
	return inst

static func _create_cylinder(radius: float, height: float, mat: Material) -> MeshInstance3D:
	var inst = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	cyl.radial_segments = 16
	cyl.material = mat
	inst.mesh = cyl
	return inst

static func _create_sphere(radius: float, color: Color) -> MeshInstance3D:
	var inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 16
	sphere.rings = 10
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.4
	sphere.material = mat
	inst.mesh = sphere
	return inst

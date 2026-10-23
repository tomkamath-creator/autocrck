# scripts/stadium/stadium_builder.gd
# Procedural 3D Cricket Stadium, 22-Yard Pitch, Stumps, Creases, Floodlights & Stands
class_name StadiumBuilder
extends RefCounted

static func build_stadium() -> Node3D:
	var stadium = Node3D.new()
	stadium.name = "CricketStadium"
	
	# 1. Outfield Grass Turf (Radius 72m)
	var outfield = _build_outfield()
	stadium.add_child(outfield)
	
	# 2. 22-Yard Pitch Strip (20.12m x 3.05m)
	var pitch = _build_pitch()
	stadium.add_child(pitch)
	
	# 3. Crease Markings (Popping, Bowling, Return creases)
	var creases = _build_crease_lines()
	stadium.add_child(creases)
	
	# 4. Wooden Wickets & Bails at both ends (z = +10.06m and z = -10.06m)
	var striker_wickets = _build_wicket_set("StrikerWickets", 10.06)
	stadium.add_child(striker_wickets)
	
	var non_striker_wickets = _build_wicket_set("NonStrikerWickets", -10.06)
	stadium.add_child(non_striker_wickets)
	
	# 5. Boundary Rope (Circumference at R = 68m)
	var boundary = _build_boundary_rope(68.0)
	stadium.add_child(boundary)
	
	# 6. LED Advertising Hoardings
	var ads = _build_ad_hoardings(69.5)
	stadium.add_child(ads)
	
	# 7. Tiered Grandstands & Stadium Bowl
	var stands = _build_stadium_stands(72.0, 95.0)
	stadium.add_child(stands)
	
	# 8. 4 Floodlight Towers with High-Intensity Spotlights
	var floodlights = _build_floodlight_towers()
	stadium.add_child(floodlights)
	
	# 9. Giant Jumbotron Replay Screen
	var jumbotron = _build_jumbotron()
	stadium.add_child(jumbotron)
	
	return stadium

# ----------------- OUTFIELD & PITCH -----------------

static func _build_outfield() -> MeshInstance3D:
	var inst = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 72.0
	cyl.bottom_radius = 72.0
	cyl.height = 0.2
	cyl.radial_segments = 64
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.52, 0.16) # Lush stadium emerald green
	mat.roughness = 0.85
	mat.metallic = 0.0
	cyl.material = mat
	inst.mesh = cyl
	inst.position = Vector3(0, -0.1, 0)
	return inst

static func _build_pitch() -> MeshInstance3D:
	var inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	# 22 yards = 20.12m long, 3.05m wide (10 feet)
	box.size = Vector3(3.05, 0.02, 22.56)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.78, 0.70, 0.50) # Hard baked turf / straw pitch
	mat.roughness = 0.90
	box.material = mat
	inst.mesh = box
	inst.position = Vector3(0, 0.005, 0)
	return inst

static func _build_crease_lines() -> Node3D:
	var node = Node3D.new()
	var white_mat = StandardMaterial3D.new()
	white_mat.albedo_color = Color(0.95, 0.95, 0.95)
	white_mat.roughness = 0.4
	
	for z_end in [10.06, -10.06]:
		var dir = 1.0 if z_end > 0 else -1.0
		# Bowling Crease through stumps (2.64m wide)
		var bowl_cr = _create_box(Vector3(2.64, 0.005, 0.05), white_mat)
		bowl_cr.position = Vector3(0, 0.016, z_end)
		node.add_child(bowl_cr)
		
		# Popping Crease (1.22m / 4ft in front of bowling crease: z = 8.84m)
		var pop_cr = _create_box(Vector3(3.66, 0.005, 0.06), white_mat)
		pop_cr.position = Vector3(0, 0.016, z_end - (dir * 1.22))
		node.add_child(pop_cr)
		
		# Return Creases (perpendicular lines from bowling to popping crease)
		for side in [-1.32, 1.32]:
			var ret_cr = _create_box(Vector3(0.05, 0.005, 1.22), white_mat)
			ret_cr.position = Vector3(side, 0.016, z_end - (dir * 0.61))
			node.add_child(ret_cr)
			
	return node

# ----------------- WICKETS & BAILS -----------------

static func _build_wicket_set(node_name: String, z_pos: float) -> Node3D:
	var wicket_set = Node3D.new()
	wicket_set.name = node_name
	wicket_set.position = Vector3(0, 0, z_pos)
	
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.85, 0.65, 0.38) # Natural polished ash wood
	wood_mat.roughness = 0.35
	wood_mat.metallic = 0.05
	
	# 3 Stumps (Height 0.71m, spacing 0.11m between centers, total width 22.8cm)
	var stump_offsets = [-0.114, 0.0, 0.114] # Off, Middle, Leg
	for i in range(3):
		var stump = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.019
		cyl.bottom_radius = 0.019
		cyl.height = 0.71
		cyl.radial_segments = 12
		cyl.material = wood_mat
		stump.mesh = cyl
		stump.position = Vector3(stump_offsets[i], 0.355, 0)
		wicket_set.add_child(stump)
	
	# 2 Wooden Bails resting across stumps
	for b in [-0.057, 0.057]:
		var bail = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.008
		cyl.bottom_radius = 0.008
		cyl.height = 0.11
		cyl.radial_segments = 8
		cyl.material = wood_mat
		bail.mesh = cyl
		bail.rotation_degrees = Vector3(0, 0, 90)
		bail.position = Vector3(b, 0.72, 0)
		wicket_set.add_child(bail)
		
	return wicket_set

# ----------------- BOUNDARY & ADVERTISING -----------------

static func _build_boundary_rope(radius: float) -> MeshInstance3D:
	var inst = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = radius - 0.08
	torus.outer_radius = radius + 0.08
	torus.rings = 64
	torus.ring_segments = 8
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.96, 0.96, 0.96) # Clean white rope
	mat.roughness = 0.6
	torus.material = mat
	inst.mesh = torus
	inst.position = Vector3(0, 0.08, 0)
	return inst

static func _build_ad_hoardings(radius: float) -> Node3D:
	var node = Node3D.new()
	var num_boards = 48
	var angle_step = TAU / num_boards
	
	var ad_colors = [
		Color(0.85, 0.1, 0.1),  # Red
		Color(0.1, 0.45, 0.85), # Blue
		Color(1.0, 0.75, 0.0),  # Yellow
		Color(0.15, 0.7, 0.3)   # Green
	]
	
	for i in range(num_boards):
		var angle = i * angle_step
		var pos = Vector3(sin(angle) * radius, 0.45, cos(angle) * radius)
		
		var board_mat = StandardMaterial3D.new()
		board_mat.albedo_color = ad_colors[i % ad_colors.size()]
		board_mat.emission_enabled = true
		board_mat.emission = board_mat.albedo_color * 0.25 # LED glow
		
		var board = _create_box(Vector3(3.8, 0.85, 0.15), board_mat)
		board.position = pos
		board.rotation = Vector3(0, angle, 0)
		node.add_child(board)
		
	return node

# ----------------- STANDS & FLOODLIGHTS -----------------

static func _build_stadium_stands(inner_r: float, outer_r: float) -> Node3D:
	var stands_node = Node3D.new()
	stands_node.name = "Grandstands"
	
	var concrete_mat = StandardMaterial3D.new()
	concrete_mat.albedo_color = Color(0.32, 0.35, 0.40)
	concrete_mat.roughness = 0.85
	
	var seat_mat = StandardMaterial3D.new()
	seat_mat.albedo_color = Color(0.12, 0.35, 0.75) # Blue grandstand seats
	seat_mat.roughness = 0.70
	
	# Tiered ring steps (3 distinct tiers)
	for tier in range(6):
		var r = inner_r + (tier * 3.8)
		var h = 1.2 + (tier * 2.8)
		var ring = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = r + 3.8
		cyl.bottom_radius = r
		cyl.height = h
		cyl.radial_segments = 48
		cyl.material = seat_mat if tier % 2 == 0 else concrete_mat
		ring.mesh = cyl
		ring.position = Vector3(0, h * 0.5, 0)
		stands_node.add_child(ring)
		
	return stands_node

static func _build_floodlight_towers() -> Node3D:
	var node = Node3D.new()
	node.name = "Floodlights"
	
	var tower_positions = [
		Vector3(70, 0, 70),
		Vector3(-70, 0, 70),
		Vector3(70, 0, -70),
		Vector3(-70, 0, -70)
	]
	
	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.65, 0.68, 0.72)
	steel_mat.metallic = 0.8
	steel_mat.roughness = 0.25
	
	for pos in tower_positions:
		var tower = Node3D.new()
		tower.position = pos
		
		# Tower Pylon (36m high)
		var pylon = _create_cylinder(1.2, 36.0, steel_mat)
		pylon.position = Vector3(0, 18.0, 0)
		tower.add_child(pylon)
		
		# Floodlight Head Frame
		var head_frame = _create_box(Vector3(8.0, 4.0, 1.5), steel_mat)
		head_frame.position = Vector3(0, 36.0, 0)
		tower.add_child(head_frame)
		
		# Actual SpotLight3D pointing onto pitch center
		var light = SpotLight3D.new()
		light.position = Vector3(0, 36.0, 0)
		light.look_at(Vector3(0, 1.0, 0))
		light.light_color = Color(0.98, 0.98, 1.0) # Crisp stadium xenon white
		light.light_energy = 5.5
		light.spot_range = 140.0
		light.spot_angle = 48.0
		light.shadow_enabled = true
		tower.add_child(light)
		
		node.add_child(tower)
		
	return node

static func _build_jumbotron() -> Node3D:
	var node = Node3D.new()
	node.name = "Jumbotron"
	node.position = Vector3(0, 24.0, -82.0)
	
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.1, 0.1, 0.12)
	var frame = _create_box(Vector3(24.0, 13.0, 2.0), frame_mat)
	node.add_child(frame)
	
	# LED Display Face
	var screen_mat = StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.04, 0.15, 0.32)
	screen_mat.emission_enabled = true
	screen_mat.emission = Color(0.1, 0.35, 0.65)
	
	var screen = _create_box(Vector3(22.0, 11.0, 0.2), screen_mat)
	screen.position = Vector3(0, 0, 1.05)
	node.add_child(screen)
	
	return node

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

extends Node3D
class_name StadiumModel

# StadiumModel: Regulation 3D Cricket Stadium with 2K PBR Outfield & Dynamic Pitch Maps

@export var boundary_radius: float = 68.0

var outfield_mesh: MeshInstance3D
var pitch_mesh: MeshInstance3D
var boundary_rope: Node3D
var grandstands: Node3D
var floodlights: Node3D

var pitch_mat: StandardMaterial3D
var grass_mat: StandardMaterial3D
var crease_mat: StandardMaterial3D
var boundary_mat: StandardMaterial3D
var stand_mat: StandardMaterial3D

func _ready() -> void:
	_init_materials()
	_build_ground()
	_build_pitch()
	_build_crease_lines()
	_build_boundary_rope()
	_build_grandstands()
	_build_floodlights()
	update_pitch_material(GameManager.selected_pitch)

func _init_materials() -> void:
	grass_mat = StandardMaterial3D.new()
	grass_mat.albedo_color = Color(1.0, 1.0, 1.0)
	if ResourceLoader.exists("res://assets/textures/pbr/turf_2k_albedo.png"):
		grass_mat.albedo_texture = load("res://assets/textures/pbr/turf_2k_albedo.png")
		grass_mat.normal_enabled = true
		grass_mat.normal_texture = load("res://assets/textures/pbr/turf_2k_normal.png")
		grass_mat.roughness_texture = load("res://assets/textures/pbr/turf_2k_roughness.png")
		grass_mat.ao_enabled = true
		grass_mat.ao_texture = load("res://assets/textures/pbr/turf_2k_ao.png")
		grass_mat.uv1_scale = Vector3(18, 18, 1)
	else:
		grass_mat.albedo_color = Color(0.18, 0.44, 0.16)
		grass_mat.roughness = 0.85

	pitch_mat = StandardMaterial3D.new()
	pitch_mat.albedo_color = Color(1.0, 1.0, 1.0)
	if ResourceLoader.exists("res://assets/textures/pbr/pitch_2k_albedo.png"):
		pitch_mat.albedo_texture = load("res://assets/textures/pbr/pitch_2k_albedo.png")
		pitch_mat.normal_enabled = true
		pitch_mat.normal_texture = load("res://assets/textures/pbr/pitch_2k_normal.png")
		pitch_mat.roughness_texture = load("res://assets/textures/pbr/pitch_2k_roughness.png")
		pitch_mat.ao_enabled = true
		pitch_mat.ao_texture = load("res://assets/textures/pbr/pitch_2k_ao.png")
	else:
		pitch_mat.albedo_color = Color(0.68, 0.58, 0.40)
		pitch_mat.roughness = 0.7

	crease_mat = StandardMaterial3D.new()
	crease_mat.albedo_color = Color(0.96, 0.96, 0.96)
	crease_mat.roughness = 0.4

	boundary_mat = StandardMaterial3D.new()
	boundary_mat.albedo_color = Color(0.1, 0.35, 0.75) # Blue sponsor foam wedges

	stand_mat = StandardMaterial3D.new()
	stand_mat.albedo_color = Color(0.25, 0.28, 0.35)
	stand_mat.roughness = 0.9

func _build_ground() -> void:
	outfield_mesh = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 75.0
	cyl.bottom_radius = 75.0
	cyl.height = 0.2
	cyl.material = grass_mat
	outfield_mesh.mesh = cyl
	outfield_mesh.position.y = -0.1
	add_child(outfield_mesh)

func _build_pitch() -> void:
	pitch_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(3.05, 0.02, 22.56) # 10ft wide, 24.67 yards total strip
	box.material = pitch_mat
	pitch_mesh.mesh = box
	pitch_mesh.position = Vector3(0, 0.005, 0)
	add_child(pitch_mesh)

func _build_crease_lines() -> void:
	# Popping crease at +9.05m and -9.05m (white line, width 3.66m, thick 0.08m)
	_create_crease_line(Vector3(0, 0.012, 9.05), Vector3(3.66, 0.01, 0.08))
	_create_crease_line(Vector3(0, 0.012, -9.05), Vector3(3.66, 0.01, 0.08))

	# Bowling crease at +10.06m and -10.06m
	_create_crease_line(Vector3(0, 0.012, 10.06), Vector3(2.64, 0.01, 0.05))
	_create_crease_line(Vector3(0, 0.012, -10.06), Vector3(2.64, 0.01, 0.05))

	# Return creases (+/- 1.32m from center)
	_create_crease_line(Vector3(1.32, 0.012, 9.55), Vector3(0.05, 0.01, 1.22))
	_create_crease_line(Vector3(-1.32, 0.012, 9.55), Vector3(0.05, 0.01, 1.22))
	_create_crease_line(Vector3(1.32, 0.012, -9.55), Vector3(0.05, 0.01, 1.22))
	_create_crease_line(Vector3(-1.32, 0.012, -9.55), Vector3(0.05, 0.01, 1.22))

func _create_crease_line(pos: Vector3, size: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	box.material = crease_mat
	mi.mesh = box
	mi.position = pos
	add_child(mi)

func _build_boundary_rope() -> void:
	boundary_rope = Node3D.new()
	add_child(boundary_rope)

	# 64 Foam Sponsor Wedges along the perimeter
	var segments: int = 64
	for i in range(segments):
		var angle: float = (float(i) / segments) * TAU
		var pos := Vector3(sin(angle) * boundary_radius, 0.15, cos(angle) * boundary_radius)
		var wedge := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(4.5, 0.3, 0.4)
		box.material = boundary_mat
		wedge.mesh = box
		wedge.position = pos
		wedge.rotation.y = angle + PI * 0.5
		boundary_rope.add_child(wedge)

func _build_grandstands() -> void:
	grandstands = Node3D.new()
	add_child(grandstands)

	# Tiered 3D Stadium Bowl
	for tier in range(3):
		var tier_mesh := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 82.0 + float(tier) * 8.0
		cyl.bottom_radius = 78.0 + float(tier) * 8.0
		cyl.height = 4.0
		cyl.material = stand_mat
		tier_mesh.mesh = cyl
		tier_mesh.position.y = 2.0 + float(tier) * 3.5
		grandstands.add_child(tier_mesh)

func _build_floodlights() -> void:
	floodlights = Node3D.new()
	add_child(floodlights)

	# 4 High-Tower Floodlights at diagonal stadium corners
	var corners: Array[Vector3] = [
		Vector3(-65, 0, -65),
		Vector3(65, 0, -65),
		Vector3(-65, 0, 65),
		Vector3(65, 0, 65)
	]

	for c in corners:
		var pylon := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.5
		cyl.bottom_radius = 1.0
		cyl.height = 24.0
		var metal_mat := StandardMaterial3D.new()
		metal_mat.albedo_color = Color(0.4, 0.42, 0.45)
		metal_mat.metallic = 0.8
		cyl.material = metal_mat
		pylon.mesh = cyl
		pylon.position = c + Vector3(0, 12, 0)
		floodlights.add_child(pylon)

		var light_head := OmniLight3D.new()
		light_head.position = c + Vector3(0, 24, 0)
		light_head.omni_range = 95.0
		light_head.light_energy = 1.5
		light_head.light_color = Color(1.0, 0.98, 0.92)
		floodlights.add_child(light_head)

func update_pitch_material(pitch_key: String) -> void:
	if DataManager.pitch_types.has(pitch_key):
		var p: Dictionary = DataManager.pitch_types[pitch_key]
		# Modulate albedo tint based on pitch type
		pitch_mat.albedo_color = p["color"]

extends Node3D
class_name StumpsModel

# StumpsModel: Regulation 3D Cricket Stumps (28 inches / 0.711m) with Dynamic Bail Dislodgement

signal stumps_broken()

var stump_off: Node3D
var stump_mid: Node3D
var stump_leg: Node3D
var bail_1: Node3D
var bail_2: Node3D

var is_broken: bool = false
var wood_mat: StandardMaterial3D

func _ready() -> void:
	_init_wood_material()
	_build_stumps()

func _init_wood_material() -> void:
	wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.85, 0.70, 0.48)
	wood_mat.roughness = 0.55

func _build_stumps() -> void:
	# Stump spacing: 0.076m apart
	stump_off = _create_stump(Vector3(-0.076, 0.355, 0))
	stump_mid = _create_stump(Vector3(0.0, 0.355, 0))
	stump_leg = _create_stump(Vector3(0.076, 0.355, 0))

	# 2 Bails on top (Y = 0.72m)
	bail_1 = _create_bail(Vector3(-0.038, 0.72, 0))
	bail_2 = _create_bail(Vector3(0.038, 0.72, 0))

func _create_stump(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	add_child(root)

	var mesh_inst := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.018
	cyl.bottom_radius = 0.018
	cyl.height = 0.711
	cyl.material = wood_mat
	mesh_inst.mesh = cyl
	root.add_child(mesh_inst)
	return root

func _create_bail(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	add_child(root)

	var mesh_inst := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.009
	cyl.bottom_radius = 0.009
	cyl.height = 0.08
	cyl.material = wood_mat
	mesh_inst.mesh = cyl
	mesh_inst.rotation.z = deg_to_rad(90.0)
	root.add_child(mesh_inst)
	return root

func shatter_stumps(impact_vel: Vector3 = Vector3(0, 3, 4)) -> void:
	if is_broken:
		return
	is_broken = true
	stumps_broken.emit()

	# Dramatic scatter physics
	var tween := create_tween().set_parallel(true)
	tween.tween_property(stump_off, "position", stump_off.position + Vector3(-0.3, 0.4, 0.8), 0.5)
	tween.tween_property(stump_off, "rotation", Vector3(1.2, 0.4, -0.6), 0.5)
	
	tween.tween_property(stump_mid, "position", stump_mid.position + Vector3(0.0, 0.6, 1.2), 0.5)
	tween.tween_property(stump_mid, "rotation", Vector3(1.8, 0.0, 0.3), 0.5)

	tween.tween_property(stump_leg, "position", stump_leg.position + Vector3(0.3, 0.3, 0.7), 0.5)
	tween.tween_property(stump_leg, "rotation", Vector3(1.0, -0.5, 0.6), 0.5)

	tween.tween_property(bail_1, "position", bail_1.position + Vector3(-0.4, 1.2, 1.5), 0.6)
	tween.tween_property(bail_1, "rotation", Vector3(3.0, 2.0, 1.0), 0.6)

	tween.tween_property(bail_2, "position", bail_2.position + Vector3(0.4, 1.4, 1.8), 0.6)
	tween.tween_property(bail_2, "rotation", Vector3(-3.0, -2.0, 2.0), 0.6)

func reset_stumps() -> void:
	is_broken = false
	stump_off.position = Vector3(-0.076, 0.355, 0)
	stump_off.rotation = Vector3.ZERO
	stump_mid.position = Vector3(0.0, 0.355, 0)
	stump_mid.rotation = Vector3.ZERO
	stump_leg.position = Vector3(0.076, 0.355, 0)
	stump_leg.rotation = Vector3.ZERO

	bail_1.position = Vector3(-0.038, 0.72, 0)
	bail_1.rotation = Vector3.ZERO
	bail_2.position = Vector3(0.038, 0.72, 0)
	bail_2.rotation = Vector3.ZERO

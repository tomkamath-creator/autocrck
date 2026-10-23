extends Control
class_name LockerRoomMenu

# LockerRoomMenu: 360-Degree Pedestal & Athlete Customization Studio

var turntable: Node3D
var player_model: PlayerCharacter
var name_input: LineEdit
var num_btn: Button
var build_btn: Button
var skin_btn: Button
var bat_btn: Button

var skin_tones: Array[Color] = [
	Color(0.88, 0.72, 0.58), # Fair
	Color(0.78, 0.58, 0.44), # Olive
	Color(0.65, 0.44, 0.32), # Tan
	Color(0.42, 0.28, 0.18)  # Deep
]
var skin_idx: int = 1

var build_types: Array[String] = ["ATHLETIC", "SLIM", "HEAVY"]
var build_idx: int = 0

var bat_willow_names: Array[String] = ["English Grade 1 Willow", "Pro Contour Swell", "Kashmir Willow"]
var bat_idx: int = 0

var jersey_colors: Array[Color] = [
	Color(0.04, 0.25, 0.65), # Classic Blue
	Color(0.92, 0.78, 0.12), # Gold Canary
	Color(0.06, 0.42, 0.22), # Dark Green
	Color(0.48, 0.08, 0.15), # Maroon
	Color(0.95, 0.95, 0.95)  # Test Whites
]
var jersey_idx: int = 0

func _ready() -> void:
	_setup_3d_viewport()
	_build_ui()
	_load_existing_custom_player()

func _process(delta: float) -> void:
	if turntable:
		turntable.rotation.y += delta * 0.75 # 360 turntable rotation

func _setup_3d_viewport() -> void:
	var subview_container := SubViewportContainer.new()
	subview_container.anchor_right = 1.0
	subview_container.anchor_bottom = 1.0
	subview_container.stretch = true
	add_child(subview_container)

	var subview := SubViewport.new()
	subview.size = Vector2i(1280, 720)
	subview.own_world_3d = true
	subview_container.add_child(subview)

	var world := World3D.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.10, 0.15)
	env.ambient_light_color = Color(0.8, 0.85, 0.95)
	env.ambient_light_energy = 0.8
	world.environment = env
	subview.world_3d = world

	# Turntable Pedestal
	turntable = Node3D.new()
	subview.add_child(turntable)

	var pedestal := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.2
	cyl.bottom_radius = 1.4
	cyl.height = 0.25
	var ped_mat := StandardMaterial3D.new()
	ped_mat.albedo_color = Color(0.2, 0.24, 0.32)
	ped_mat.metallic = 0.8
	ped_mat.roughness = 0.2
	cyl.material = ped_mat
	pedestal.mesh = cyl
	pedestal.position.y = -0.125
	turntable.add_child(pedestal)

	# Player Character on Pedestal
	player_model = PlayerCharacter.new()
	player_model.role = PlayerCharacter.PlayerRole.BATSMAN
	player_model.team_id = "IND"
	turntable.add_child(player_model)
	player_model.play_animation("stance")

	# Pedestal Spotlights & Camera
	var key_light := DirectionalLight3D.new()
	key_light.position = Vector3(5, 10, 8)
	key_light.rotation = Vector3(deg_to_rad(-45), deg_to_rad(30), 0)
	key_light.light_energy = 1.8
	subview.add_child(key_light)

	var rim_light := OmniLight3D.new()
	rim_light.position = Vector3(-3, 3, -4)
	rim_light.light_energy = 2.0
	rim_light.light_color = Color(0.3, 0.7, 1.0)
	subview.add_child(rim_light)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.15, 3.2)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	subview.add_child(cam)

func _build_ui() -> void:
	# Customization Controls Panel on Left
	var panel := PanelContainer.new()
	panel.offset_left = 40
	panel.offset_top = 40
	panel.offset_right = 380
	panel.offset_bottom = 680
	var style_p := StyleBoxFlat.new()
	style_p.bg_color = Color(0.06, 0.08, 0.12, 0.88)
	style_p.corner_radius_top_left = 16
	style_p.corner_radius_top_right = 16
	style_p.corner_radius_bottom_left = 16
	style_p.corner_radius_bottom_right = 16
	panel.add_theme_stylebox_override("panel", style_p)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "👕 CUSTOMIZATION STUDIO"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title)

	# Name Input
	var name_lbl := Label.new()
	name_lbl.text = "PLAYER NAME:"
	vbox.add_child(name_lbl)
	name_input = LineEdit.new()
	name_input.text = DataManager.custom_player["name"]
	vbox.add_child(name_input)

	# Jersey Number
	num_btn = Button.new()
	num_btn.text = "JERSEY NUMBER: %d" % DataManager.custom_player["number"]
	num_btn.pressed.connect(func():
		var n: int = (DataManager.custom_player["number"] % 99) + 1
		DataManager.custom_player["number"] = n
		num_btn.text = "JERSEY NUMBER: %d" % n
	)
	vbox.add_child(num_btn)

	# Build Type
	build_btn = Button.new()
	build_btn.text = "BUILD: ATHLETIC"
	build_btn.pressed.connect(func():
		build_idx = (build_idx + 1) % build_types.size()
		_apply_build()
	)
	vbox.add_child(build_btn)

	# Skin Tone
	skin_btn = Button.new()
	skin_btn.text = "SKIN TONE: [CYCLE]"
	skin_btn.pressed.connect(func():
		skin_idx = (skin_idx + 1) % skin_tones.size()
		player_model.skin_mat.albedo_color = skin_tones[skin_idx]
	)
	vbox.add_child(skin_btn)

	# Bat Willow
	bat_btn = Button.new()
	bat_btn.text = "WILLOW: English Grade 1"
	bat_btn.pressed.connect(func():
		bat_idx = (bat_idx + 1) % bat_willow_names.size()
		bat_btn.text = "WILLOW: %s" % bat_willow_names[bat_idx]
	)
	vbox.add_child(bat_btn)

	# Jersey Palette
	var jersey_btn := Button.new()
	jersey_btn.text = "JERSEY COLOR: [CYCLE]"
	jersey_btn.pressed.connect(func():
		jersey_idx = (jersey_idx + 1) % jersey_colors.size()
		var col: Color = jersey_colors[jersey_idx]
		player_model.jersey_mat.albedo_color = col
		player_model.pants_mat.albedo_color = col
		player_model.helmet_mat.albedo_color = col
	)
	vbox.add_child(jersey_btn)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Save & Exit Button
	var save_btn := Button.new()
	save_btn.text = "💾 SAVE & RETURN"
	save_btn.custom_minimum_size = Vector2(0, 48)
	var style_s := StyleBoxFlat.new()
	style_s.bg_color = Color(0.1, 0.65, 0.25)
	style_s.corner_radius_top_left = 10
	style_s.corner_radius_top_right = 10
	style_s.corner_radius_bottom_left = 10
	style_s.corner_radius_bottom_right = 10
	save_btn.add_theme_stylebox_override("normal", style_s)
	save_btn.pressed.connect(_on_save_and_exit)
	vbox.add_child(save_btn)

func _load_existing_custom_player() -> void:
	name_input.text = DataManager.custom_player["name"]
	_apply_build()

func _apply_build() -> void:
	var b_type: String = build_types[build_idx]
	build_btn.text = "BUILD: %s" % b_type
	if b_type == "SLIM":
		player_model.chest.scale = Vector3(0.9, 1.0, 0.88)
	elif b_type == "HEAVY":
		player_model.chest.scale = Vector3(1.15, 1.0, 1.15)
	else:
		player_model.chest.scale = Vector3(1.0, 1.0, 1.0)

func _on_save_and_exit() -> void:
	DataManager.custom_player["name"] = name_input.text
	DataManager.custom_player["build_type"] = build_types[build_idx]
	DataManager.custom_player["skin_tone"] = skin_idx
	DataManager.save_all_data()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

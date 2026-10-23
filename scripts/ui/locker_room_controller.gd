# scripts/ui/locker_room_controller.gd
# 360° Turntable Locker Room & Player Customization Studio for CricStrike 3D
extends Control

@onready var turntable: Node3D = $TurntableSubViewport/SubViewport/TurntablePedestal
@onready var edit_name: LineEdit = $CustomPanel/EditName
@onready var spin_number: SpinBox = $CustomPanel/SpinNumber
@onready var option_build: OptionButton = $CustomPanel/OptionBuild
@onready var option_skin: OptionButton = $CustomPanel/OptionSkin
@onready var option_role: OptionButton = $CustomPanel/OptionRole
@onready var btn_save: Button = $CustomPanel/BtnSave
@onready var btn_back: Button = $BtnBack

var player_model: Node3D

func _ready() -> void:
	_init_ui_values()
	_spawn_turntable_model()
	_connect_events()

func _process(delta: float) -> void:
	if turntable:
		turntable.rotate_y(delta * 0.45) # Smooth 360 turntable rotation!

func _init_ui_values() -> void:
	var data = PersistenceManager.custom_player_data
	if edit_name: edit_name.text = data.get("name", "V. STRIKER")
	if spin_number: spin_number.value = data.get("jersey_number", 18)
	
	if option_build:
		option_build.clear()
		option_build.add_item("Athletic")
		option_build.add_item("Slim")
		option_build.add_item("Heavy")
		var b_idx = ["Athletic", "Slim", "Heavy"].find(data.get("build_type", "Athletic"))
		option_build.selected = max(0, b_idx)
	
	if option_skin:
		option_skin.clear()
		option_skin.add_item("Fair")
		option_skin.add_item("Wheatish")
		option_skin.add_item("Dark")
		option_skin.selected = data.get("skin_tone", 1)
	
	if option_role:
		option_role.clear()
		option_role.add_item("Batsman")
		option_role.add_item("Bowler")
		option_role.add_item("Wicketkeeper")
		var r_idx = ["Batsman", "Bowler", "Wicketkeeper"].find(data.get("role", "Batsman"))
		option_role.selected = max(0, r_idx)

func _spawn_turntable_model() -> void:
	if not turntable:
		return
	if player_model:
		player_model.queue_free()
	
	var data = PersistenceManager.custom_player_data
	var p_name = data.get("name", "V. STRIKER")
	var p_num = int(data.get("jersey_number", 18))
	var p_role = data.get("role", "Batsman")
	var p_build = data.get("build_type", "Athletic")
	var p_skin = int(data.get("skin_tone", 1))
	
	player_model = PlayerMeshBuilder.build_player_model(p_role, "India", p_name, p_num, p_build, p_skin)
	turntable.add_child(player_model)
	
	var anim = CricketAnimator.new()
	anim.init(player_model)
	anim.play("stance", 1.0, true)

func _connect_events() -> void:
	if btn_save: btn_save.pressed.connect(_on_save_pressed)
	if btn_back: btn_back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	
	if option_build: option_build.item_selected.connect(func(i): _refresh_preview())
	if option_skin: option_skin.item_selected.connect(func(i): _refresh_preview())
	if option_role: option_role.item_selected.connect(func(i): _refresh_preview())

func _refresh_preview() -> void:
	var data = PersistenceManager.custom_player_data
	if edit_name: data["name"] = edit_name.text
	if spin_number: data["jersey_number"] = int(spin_number.value)
	if option_build: data["build_type"] = option_build.get_item_text(option_build.selected)
	if option_skin: data["skin_tone"] = option_skin.selected
	if option_role: data["role"] = option_role.get_item_text(option_role.selected)
	_spawn_turntable_model()

func _on_save_pressed() -> void:
	AudioManager.play_ui_click()
	_refresh_preview()
	PersistenceManager.save_custom_player()

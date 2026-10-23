extends Control
class_name MainMenu

# MainMenu: Console-Grade Landing Hub for CricStrike 3D

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	# Dark stadium background theme
	var bg := ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.06, 0.08, 0.12)
	add_child(bg)

	# Header Profile Bar
	var header := PanelContainer.new()
	header.anchor_right = 1.0
	header.offset_bottom = 64
	var style_h := StyleBoxFlat.new()
	style_h.bg_color = Color(0.08, 0.12, 0.18, 0.9)
	style_h.border_width_bottom = 2
	style_h.border_color = Color(0.95, 0.75, 0.12)
	header.add_theme_stylebox_override("panel", style_h)
	add_child(header)

	var hbox_h := HBoxContainer.new()
	hbox_h.offset_left = 24
	hbox_h.offset_right = -24
	header.add_child(hbox_h)

	var title_lbl := Label.new()
	title_lbl.text = "CRICSTRIKE 3D"
	title_lbl.add_theme_font_size_override("font_size", 26)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	hbox_h.add_child(title_lbl)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_h.add_child(spacer)

	var coins_lbl := Label.new()
	coins_lbl.text = "🪙 ₹%s" % _format_number(DataManager.profile["coins"])
	coins_lbl.add_theme_font_size_override("font_size", 18)
	coins_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	hbox_h.add_child(coins_lbl)

	# Main Mode Cards VBox
	var vbox_modes := VBoxContainer.new()
	vbox_modes.anchor_left = 0.5
	vbox_modes.anchor_top = 0.5
	vbox_modes.anchor_right = 0.5
	vbox_modes.anchor_bottom = 0.5
	vbox_modes.offset_left = -220
	vbox_modes.offset_top = -180
	vbox_modes.offset_right = 220
	vbox_modes.offset_bottom = 220
	vbox_modes.add_theme_constant_override("separation", 14)
	add_child(vbox_modes)

	vbox_modes.add_child(_create_mode_btn("🏏 QUICK MATCH", "Pick any 2 teams and play instantly", Color(0.1, 0.45, 0.85), func():
		get_tree().change_scene_to_file("res://scenes/quick_match.tscn")
	))

	vbox_modes.add_child(_create_mode_btn("⚡ SUPER OVER", "High-voltage 1-over chase scenario", Color(0.85, 0.2, 0.2), func():
		GameManager.setup_match("IND", "AUS", 1, "GREEN_TURF", "HARD", GameManager.GameMode.SUPER_OVER)
		get_tree().change_scene_to_file("res://scenes/match.tscn")
	))

	vbox_modes.add_child(_create_mode_btn("🏆 WORLD TOURNAMENT", "8-Team Championship Bracket & Points Table", Color(0.85, 0.65, 0.1), func():
		get_tree().change_scene_to_file("res://scenes/tournament.tscn")
	))

	vbox_modes.add_child(_create_mode_btn("💰 MEGA AUCTION", "Bid against franchise AI teams with ₹100 Cr purse", Color(0.2, 0.65, 0.35), func():
		get_tree().change_scene_to_file("res://scenes/auction.tscn")
	))

	vbox_modes.add_child(_create_mode_btn("👕 LOCKER ROOM & CUSTOMIZER", "360° Pedestal, player gear, build & kits", Color(0.45, 0.25, 0.75), func():
		get_tree().change_scene_to_file("res://scenes/locker_room.tscn")
	))

func _create_mode_btn(title: String, desc: String, accent_color: Color, on_click: Callable) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(440, 64)
	btn.text = "%s\n%s" % [title, desc]
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent_color.r * 0.3, accent_color.g * 0.3, accent_color.b * 0.3, 0.95)
	style.border_width_left = 6
	style.border_color = accent_color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	btn.add_theme_stylebox_override("normal", style)
	btn.pressed.connect(on_click)
	return btn

func _format_number(n: int) -> String:
	if n >= 10000000:
		return "%.2f Cr" % (float(n) / 10000000.0)
	elif n >= 100000:
		return "%.2f L" % (float(n) / 100000.0)
	return str(n)

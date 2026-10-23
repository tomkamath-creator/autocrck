# scripts/ui/touch_action_button.gd
# Ergonomic Mobile Touch Action Button with Tactile Feedback for CricStrike 3D
class_name TouchActionButton
extends Button

signal action_triggered(action_name: String)

@export var action_label: String = "DRIVE"
@export var theme_accent: Color = Color(0.0, 0.8, 1.0) # Cyan default

var is_down: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(88, 88)
	flat = true
	button_down.connect(_on_down)
	button_up.connect(_on_up)

func _on_down() -> void:
	is_down = true
	scale = Vector2(0.92, 0.92)
	pivot_offset = size * 0.5
	AudioManager.play_ui_click()
	emit_signal("action_triggered", action_label)
	queue_redraw()

func _on_up() -> void:
	is_down = false
	scale = Vector2(1.0, 1.0)
	queue_redraw()

func _draw() -> void:
	var rect = Rect2(Vector2.ZERO, size)
	var bg_color = theme_accent if is_down else Color(0.08, 0.14, 0.22, 0.88)
	var border_color = Color(1, 1, 1, 0.9) if is_down else theme_accent
	
	# Rounded aesthetic stadium pill / disc
	draw_rect(rect, bg_color, true, 18.0)
	draw_rect(rect, border_color, false, 3.0, 18.0)
	
	# Action text
	var font = ThemeDB.fallback_font
	var font_size = 18
	var text_color = Color(0.05, 0.08, 0.12) if is_down else Color(1, 1, 1, 0.95)
	var text_size = font.get_string_size(action_label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos = Vector2((size.x - text_size.x) * 0.5, (size.y + text_size.y * 0.7) * 0.5)
	draw_string(font, text_pos, action_label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)

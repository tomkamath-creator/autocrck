# scripts/ui/virtual_joystick.gd
# 360° Multi-Touch Virtual Thumb Joystick for Mobile Cricket Shot Placement
class_name VirtualJoystick
extends Control

signal joystick_vector_changed(vector: Vector2)

@export var max_radius: float = 64.0
@export var deadzone: float = 0.12

var touch_id: int = -1
var is_active: bool = false
var center_pos: Vector2 = Vector2.ZERO
var current_pos: Vector2 = Vector2.ZERO
var output_vector: Vector2 = Vector2.ZERO

func _ready() -> void:
	custom_minimum_size = Vector2(160, 160)
	center_pos = size * 0.5
	current_pos = center_pos

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1:
			touch_id = event.index
			is_active = true
			_update_joystick(event.position)
		elif not event.pressed and event.index == touch_id:
			_release_joystick()
			
	elif event is InputEventScreenDrag:
		if event.index == touch_id:
			_update_joystick(event.position)

func _update_joystick(touch_pos: Vector2) -> void:
	center_pos = size * 0.5
	var diff = touch_pos - center_pos
	var dist = diff.length()
	
	if dist > max_radius:
		diff = diff.normalized() * max_radius
	
	current_pos = center_pos + diff
	
	var norm_dist = diff.length() / max_radius
	if norm_dist < deadzone:
		output_vector = Vector2.ZERO
	else:
		output_vector = diff.normalized() * ((norm_dist - deadzone) / (1.0 - deadzone))
	
	emit_signal("joystick_vector_changed", output_vector)
	queue_redraw()

func _release_joystick() -> void:
	touch_id = -1
	is_active = false
	current_pos = size * 0.5
	output_vector = Vector2.ZERO
	emit_signal("joystick_vector_changed", Vector2.ZERO)
	queue_redraw()

func _draw() -> void:
	var center = size * 0.5
	
	# Outer glow ring
	var ring_color = Color(0.0, 0.85, 1.0, 0.35) if is_active else Color(1.0, 1.0, 1.0, 0.18)
	draw_arc(center, max_radius, 0, TAU, 32, ring_color, 3.0, true)
	draw_circle(center, max_radius * 0.95, Color(0.05, 0.15, 0.25, 0.25))
	
	# 8 Directional guide notches
	for i in range(8):
		var angle = i * (TAU / 8.0)
		var p1 = center + Vector2(cos(angle), sin(angle)) * (max_radius * 0.75)
		var p2 = center + Vector2(cos(angle), sin(angle)) * (max_radius * 0.95)
		draw_line(p1, p2, Color(1, 1, 1, 0.25), 1.5)
	
	# Thumb stick knob
	var knob_color = Color(0.0, 0.9, 1.0, 0.85) if is_active else Color(0.85, 0.9, 1.0, 0.55)
	draw_circle(current_pos, 28.0, knob_color)
	draw_circle(current_pos, 10.0, Color(1, 1, 1, 0.95))

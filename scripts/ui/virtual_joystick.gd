extends Control
class_name VirtualJoystick

# VirtualJoystick: High-Performance 360-Degree Multi-Touch Virtual Thumb Joystick

signal joystick_moved(direction: Vector2)
signal joystick_released()

@export var clamp_radius: float = 64.0
@export var base_color: Color = Color(1, 1, 1, 0.25)
@export var knob_color: Color = Color(0.2, 0.8, 1.0, 0.85)

var touch_id: int = -1
var is_pressed: bool = false
var joystick_vector: Vector2 = Vector2.ZERO
var knob_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	custom_minimum_size = Vector2(160, 160)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1:
			touch_id = event.index
			is_pressed = true
			_update_knob(event.position)
		elif not event.pressed and event.index == touch_id:
			_reset_joystick()
	elif event is InputEventScreenDrag and event.index == touch_id:
		_update_knob(event.position)
	elif event is InputEventMouseButton:
		if event.pressed and touch_id == -1:
			touch_id = 0
			is_pressed = true
			_update_knob(event.position)
		elif not event.pressed and touch_id == 0:
			_reset_joystick()
	elif event is InputEventMouseMotion and touch_id == 0:
		_update_knob(event.position)

func _update_knob(touch_pos: Vector2) -> void:
	var center := size * 0.5
	var offset: Vector2 = touch_pos - center
	if offset.length() > clamp_radius:
		offset = offset.normalized() * clamp_radius
	
	knob_position = offset
	joystick_vector = offset / clamp_radius
	joystick_moved.emit(joystick_vector)
	queue_redraw()

func _reset_joystick() -> void:
	touch_id = -1
	is_pressed = false
	knob_position = Vector2.ZERO
	joystick_vector = Vector2.ZERO
	joystick_released.emit()
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	# Outer base ring
	draw_circle(center, clamp_radius + 12.0, base_color)
	draw_arc(center, clamp_radius + 12.0, 0, TAU, 32, Color(1, 1, 1, 0.4), 2.0)
	
	# Directional sector ticks (8 sectors)
	for i in range(8):
		var angle: float = (float(i) / 8.0) * TAU
		var p1 := center + Vector2(cos(angle), sin(angle)) * (clamp_radius - 8.0)
		var p2 := center + Vector2(cos(angle), sin(angle)) * (clamp_radius + 8.0)
		draw_line(p1, p2, Color(1, 1, 1, 0.3), 1.5)

	# Active knob
	var knob_center := center + knob_position
	var cur_color := knob_color if is_pressed else Color(0.8, 0.8, 0.8, 0.6)
	draw_circle(knob_center, 28.0, cur_color)
	draw_arc(knob_center, 28.0, 0, TAU, 24, Color.WHITE, 2.0)

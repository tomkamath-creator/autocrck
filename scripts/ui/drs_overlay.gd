# scripts/ui/drs_overlay.gd
# DRS (Decision Review System) Broadcast TV Overlay with UltraEdge & Hawkeye Display
class_name DRSOverlay
extends Control

signal review_completed()

@onready var panel_ultraedge: Panel = $PanelUltraEdge
@onready var panel_hawkeye: Panel = $PanelHawkeye
@onready var label_decision: Label = $DecisionStamp

var waveform_data: Array[float] = []
var is_active: bool = false
var step_timer: float = 0.0
var current_step: int = 0

func _ready() -> void:
	visible = false

func start_review(is_edge_review: bool, hawkeye_data: Dictionary) -> void:
	visible = true
	is_active = true
	step_timer = 0.0
	current_step = 0
	
	if label_decision: label_decision.visible = false
	if panel_ultraedge: panel_ultraedge.visible = false
	if panel_hawkeye: panel_hawkeye.visible = false
	
	AudioManager.play_drs_beep()
	
	if is_edge_review:
		# UltraEdge Snickometer Review
		if panel_ultraedge: panel_ultraedge.visible = true
		waveform_data = DRSManager.generate_snickometer_waveform(80, 42) # Edge detected!
		queue_redraw()
		
		var t = create_tween()
		t.tween_interval(2.2)
		t.tween_callback(func(): _show_decision(true, "OUT - CAUGHT BEHIND"))
	else:
		# Hawkeye LBW Ball Tracking Review
		if panel_hawkeye:
			panel_hawkeye.visible = true
			var lbl_pitch = panel_hawkeye.get_node_or_null("LabelPitch")
			var lbl_impact = panel_hawkeye.get_node_or_null("LabelImpact")
			var lbl_wickets = panel_hawkeye.get_node_or_null("LabelWickets")
			
			if lbl_pitch: lbl_pitch.text = "PITCHING: " + hawkeye_data.get("pitched", "In Line").to_upper()
			if lbl_impact: lbl_impact.text = "IMPACT: " + hawkeye_data.get("impact", "In Line").to_upper()
			if lbl_wickets: lbl_wickets.text = "WICKETS: " + hawkeye_data.get("wickets", "Hitting").to_upper()
		
		var t = create_tween()
		t.tween_interval(2.5)
		t.tween_callback(func(): _show_decision(hawkeye_data.get("is_out", true), "OUT - LBW" if hawkeye_data.get("is_out", true) else "NOT OUT"))

func _show_decision(is_out: bool, text_desc: String) -> void:
	if label_decision:
		label_decision.visible = true
		label_decision.text = text_desc
		label_decision.modulate = Color(1.0, 0.2, 0.2) if is_out else Color(0.2, 0.9, 0.3)
	
	AudioManager.play_whistle()
	var t = create_tween()
	t.tween_interval(2.0)
	t.tween_callback(func():
		visible = false
		is_active = false
		emit_signal("review_completed")
	)

func _draw() -> void:
	if not visible or waveform_data.is_empty():
		return
	
	# Draw Snickometer audio waveform oscilloscope in panel_ultraedge
	var rect = panel_ultraedge.get_rect() if panel_ultraedge else Rect2(400, 200, 480, 240)
	var center_y = rect.position.y + rect.size.y * 0.5
	var step_x = rect.size.x / float(waveform_data.size())
	
	# Draw central zero line
	draw_line(Vector2(rect.position.x, center_y), Vector2(rect.position.x + rect.size.x, center_y), Color(0.2, 0.5, 0.3, 0.5), 1.0)
	
	# Draw waveform
	for i in range(waveform_data.size() - 1):
		var p1 = Vector2(rect.position.x + (i * step_x), center_y - (waveform_data[i] * rect.size.y * 0.45))
		var p2 = Vector2(rect.position.x + ((i + 1) * step_x), center_y - (waveform_data[i + 1] * rect.size.y * 0.45))
		draw_line(p1, p2, Color(0.1, 1.0, 0.4, 0.95), 2.5)

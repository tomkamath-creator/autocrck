extends Control
class_name AuctionMenu

# AuctionMenu: Offline Franchise Mega Auction with AI Bidding Wars & Purse Management

var player_name_lbl: Label
var player_role_lbl: Label
var player_rating_lbl: Label
var base_price_lbl: Label
var current_bid_lbl: Label
var bidder_lbl: Label
var timer_lbl: Label
var user_purse_lbl: Label
var roster_vbox: VBoxContainer
var bid_btn: Button

func _ready() -> void:
	AuctionManager.init_auction("MB")
	AuctionManager.bid_updated.connect(_on_bid_updated)
	AuctionManager.player_sold.connect(_on_player_sold)
	AuctionManager.auction_ended.connect(_on_auction_ended)
	_build_ui()
	_update_view()

func _process(delta: float) -> void:
	AuctionManager.process_auction_ai(delta)
	if timer_lbl:
		timer_lbl.text = "⏱ TIME: %.1fs" % max(AuctionManager.countdown_timer, 0.0)

func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var bg := ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.06, 0.08, 0.12)
	add_child(bg)

	# Header
	var header := PanelContainer.new()
	header.anchor_right = 1.0
	header.offset_bottom = 60
	var style_h := StyleBoxFlat.new()
	style_h.bg_color = Color(0.08, 0.12, 0.18)
	style_h.border_width_bottom = 2
	style_h.border_color = Color(0.2, 0.7, 0.4)
	header.add_theme_stylebox_override("panel", style_h)
	add_child(header)

	var hbox_h := HBoxContainer.new()
	hbox_h.offset_left = 24
	hbox_h.offset_right = -24
	header.add_child(hbox_h)

	var title := Label.new()
	title.text = "💰 FRANCHISE MEGA AUCTION"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4))
	hbox_h.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_h.add_child(spacer)

	user_purse_lbl = Label.new()
	user_purse_lbl.text = "PURSE: ₹100.00 Cr"
	user_purse_lbl.add_theme_font_size_override("font_size", 18)
	user_purse_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	hbox_h.add_child(user_purse_lbl)

	# Left Player Card
	var left_card := PanelContainer.new()
	left_card.offset_left = 40
	left_card.offset_top = 80
	left_card.offset_right = 640
	left_card.offset_bottom = 540
	var style_lc := StyleBoxFlat.new()
	style_lc.bg_color = Color(0.1, 0.14, 0.22, 0.95)
	style_lc.corner_radius_top_left = 16
	style_lc.corner_radius_top_right = 16
	style_lc.corner_radius_bottom_left = 16
	style_lc.corner_radius_bottom_right = 16
	left_card.add_theme_stylebox_override("panel", style_lc)
	add_child(left_card)

	var vbox_l := VBoxContainer.new()
	vbox_l.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_l.add_theme_constant_override("separation", 14)
	vbox_l.offset_left = 24
	vbox_l.offset_top = 24
	vbox_l.offset_right = -24
	vbox_l.offset_bottom = -24
	left_card.add_child(vbox_l)

	player_name_lbl = Label.new()
	player_name_lbl.text = "PLAYER NAME"
	player_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_name_lbl.add_theme_font_size_override("font_size", 28)
	player_name_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	vbox_l.add_child(player_name_lbl)

	player_role_lbl = Label.new()
	player_role_lbl.text = "ROLE: ALL_ROUNDER"
	player_role_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_role_lbl.add_theme_font_size_override("font_size", 16)
	vbox_l.add_child(player_role_lbl)

	player_rating_lbl = Label.new()
	player_rating_lbl.text = "OVERALL RATING: 95"
	player_rating_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_rating_lbl.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	vbox_l.add_child(player_rating_lbl)

	base_price_lbl = Label.new()
	base_price_lbl.text = "BASE PRICE: ₹2.00 Cr"
	base_price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_l.add_child(base_price_lbl)

	current_bid_lbl = Label.new()
	current_bid_lbl.text = "CURRENT BID: ₹2.00 Cr"
	current_bid_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	current_bid_lbl.add_theme_font_size_override("font_size", 24)
	current_bid_lbl.add_theme_color_override("font_color", Color(0.2, 0.95, 0.35))
	vbox_l.add_child(current_bid_lbl)

	bidder_lbl = Label.new()
	bidder_lbl.text = "HIGHEST BIDDER: None"
	bidder_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bidder_lbl.add_theme_font_size_override("font_size", 18)
	vbox_l.add_child(bidder_lbl)

	timer_lbl = Label.new()
	timer_lbl.text = "⏱ TIME: 4.0s"
	timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_lbl.add_theme_font_size_override("font_size", 20)
	timer_lbl.add_theme_color_override("font_color", Color(0.95, 0.3, 0.3))
	vbox_l.add_child(timer_lbl)

	bid_btn = Button.new()
	bid_btn.text = "🔥 PLACE BID (+₹25 L / +₹50 L)"
	bid_btn.custom_minimum_size = Vector2(340, 54)
	var style_b := StyleBoxFlat.new()
	style_b.bg_color = Color(0.12, 0.65, 0.28)
	style_b.corner_radius_top_left = 12
	style_b.corner_radius_top_right = 12
	style_b.corner_radius_bottom_left = 12
	style_b.corner_radius_bottom_right = 12
	bid_btn.add_theme_stylebox_override("normal", style_b)
	bid_btn.pressed.connect(_on_bid_pressed)
	vbox_l.add_child(bid_btn)

	# Right Squad Panel
	var right_panel := PanelContainer.new()
	right_panel.offset_left = 680
	right_panel.offset_top = 80
	right_panel.offset_right = 1240
	right_panel.offset_bottom = 540
	var style_rp := StyleBoxFlat.new()
	style_rp.bg_color = Color(0.09, 0.12, 0.18, 0.95)
	style_rp.corner_radius_top_left = 16
	style_rp.corner_radius_top_right = 16
	style_rp.corner_radius_bottom_left = 16
	style_rp.corner_radius_bottom_right = 16
	right_panel.add_theme_stylebox_override("panel", style_rp)
	add_child(right_panel)

	var vbox_r := VBoxContainer.new()
	vbox_r.offset_left = 20
	vbox_r.offset_top = 20
	vbox_r.offset_right = -20
	vbox_r.offset_bottom = -20
	right_panel.add_child(vbox_r)

	var squad_title := Label.new()
	squad_title.text = "YOUR SQUAD (MUMBAI BLASTERS)"
	squad_title.add_theme_font_size_override("font_size", 18)
	squad_title.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	vbox_r.add_child(squad_title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 360
	vbox_r.add_child(scroll)

	roster_vbox = VBoxContainer.new()
	scroll.add_child(roster_vbox)

	# Bottom Back Button
	var back_btn := Button.new()
	back_btn.text = "⬅ BACK TO MENU"
	back_btn.offset_left = 40
	back_btn.offset_top = 560
	back_btn.offset_right = 240
	back_btn.offset_bottom = 615
	back_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	add_child(back_btn)

func _update_view() -> void:
	var purse: int = AuctionManager.franchise_purses[AuctionManager.user_franchise_id]
	user_purse_lbl.text = "PURSE: ₹%s" % _format_crores(purse)

	if AuctionManager.current_player_idx < AuctionManager.auction_pool.size():
		var p: Dictionary = AuctionManager.auction_pool[AuctionManager.current_player_idx]
		player_name_lbl.text = p["name"]
		player_role_lbl.text = "ROLE: %s" % p["role"]
		player_rating_lbl.text = "OVERALL RATING: %d" % p["rating"]
		base_price_lbl.text = "BASE PRICE: ₹%s" % _format_crores(p["base_price"])
		current_bid_lbl.text = "CURRENT BID: ₹%s" % _format_crores(AuctionManager.current_bid)
		bidder_lbl.text = "HIGHEST BIDDER: %s" % AuctionManager.current_bidder

	# Update squad roster
	for child in roster_vbox.get_children():
		child.queue_free()

	var squad: Array = AuctionManager.franchise_squads[AuctionManager.user_franchise_id]
	for p in squad:
		var lbl := Label.new()
		lbl.text = "• %s (%s) - Rating %d" % [p["name"], p["role"], p["rating"]]
		roster_vbox.add_child(lbl)

func _on_bid_pressed() -> void:
	AuctionManager.place_user_bid()

func _on_bid_updated(_p: Dictionary, _bid: int, _bidder: String) -> void:
	_update_view()

func _on_player_sold(_p: Dictionary, _bid: int, _buyer: String) -> void:
	_update_view()

func _on_auction_ended() -> void:
	player_name_lbl.text = "AUCTION CONCLUDED!"
	bid_btn.disabled = true

func _format_crores(n: int) -> String:
	return "%.2f Cr" % (float(n) / 10000000.0)

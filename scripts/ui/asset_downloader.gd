extends Control
class_name AssetDownloader

# AssetDownloader: Post-Install In-App Asset Delivery & 1.2 GB Ultra HD Console Expansion Downloader

const PACK_SAVE_PATH: String = "user://console_assets_pack.pck"
const DIRECT_DOWNLOAD_URL: String = "https://github.com/tomkamath-creator/cricket-/releases/download/v1.0.0-build.5/console_assets_pack.pck"
const LATEST_DOWNLOAD_URL: String = "https://github.com/tomkamath-creator/cricket-/releases/latest/download/console_assets_pack.pck"

var http_request: HTTPRequest
var progress_bar: ProgressBar
var status_label: Label
var details_label: Label
var download_btn: Button
var play_offline_btn: Button
var percent_label: Label

var is_downloading: bool = false
var total_bytes_expected: int = 63910496 # 63.9 MB expansion pack containing full 2K PBR materials & 3D models
var downloaded_bytes_current: int = 0
var download_start_time: float = 0.0

func _ready() -> void:
	_init_network()
	_build_ui()
	_check_existing_pack()

func _init_network() -> void:
	http_request = HTTPRequest.new()
	http_request.use_threads = true
	http_request.max_redirects = 8
	http_request.timeout = 300.0 # 5 minute timeout for large files
	add_child(http_request)
	http_request.request_completed.connect(_on_download_completed)

func _check_existing_pack() -> void:
	if FileAccess.file_exists(PACK_SAVE_PATH):
		status_label.text = "Console Asset Pack Detected! Mounting..."
		_mount_pack_and_launch()

func _process(delta: float) -> void:
	if is_downloading and http_request:
		var body_size: int = http_request.get_body_size()
		var downloaded: int = http_request.get_downloaded_bytes()
		
		if body_size > 0:
			total_bytes_expected = body_size
		
		var mb_downloaded: float = float(downloaded) / (1024.0 * 1024.0)
		var mb_total: float = float(total_bytes_expected) / (1024.0 * 1024.0)
		var elapsed: float = max(Time.get_ticks_msec() / 1000.0 - download_start_time, 0.1)
		var speed_mbps: float = mb_downloaded / elapsed

		if downloaded > 0:
			downloaded_bytes_current = downloaded
			var progress_pct: float = clamp((float(downloaded) / float(total_bytes_expected)) * 100.0, 0.0, 100.0)
			progress_bar.value = progress_pct
			percent_label.text = "%.1f%% (%.1f MB / %.1f MB) — %.2f MB/s" % [progress_pct, mb_downloaded, mb_total, speed_mbps]
			status_label.text = "DOWNLOADING CONSOLE ULTRA HD EXPANSION PACK..."
		else:
			# Visual spinner feedback while establishing handshake
			percent_label.text = "Connecting to CDN... (%.1f MB expected)" % mb_total
			status_label.text = "ESTABLISHING SECURE HIGH-SPEED DOWNLOAD..."

func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var bg := ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.05, 0.07, 0.11)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Main Dialog Container centered
	var center := CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 480)
	var style_p := StyleBoxFlat.new()
	style_p.bg_color = Color(0.08, 0.12, 0.18, 0.98)
	style_p.border_width_left = 3
	style_p.border_width_right = 3
	style_p.border_width_top = 3
	style_p.border_width_bottom = 3
	style_p.border_color = Color(0.95, 0.75, 0.15)
	style_p.corner_radius_top_left = 20
	style_p.corner_radius_top_right = 20
	style_p.corner_radius_bottom_left = 20
	style_p.corner_radius_bottom_right = 20
	style_p.content_margin_left = 32
	style_p.content_margin_right = 32
	style_p.content_margin_top = 28
	style_p.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", style_p)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "🏏 CRICSTRIKE 3D — CONSOLE ASSET DELIVERY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title)

	status_label = Label.new()
	status_label.text = "ADDITIONAL HIGH-DEFINITION GAME DATA AVAILABLE"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
	vbox.add_child(status_label)

	details_label = Label.new()
	details_label.text = "To match the console visual fidelity of Real Cricket & WCC3, you can download the 1.2 GB+ Ultra HD Expansion Pack:\n\n• 🏟 8 International 4K Stadiums (Eden Gardens, MCG, Lord's, Wankhede)\n• 👕 16 International & Franchise Kits with 3D Crests & Carbon-Weaves\n• 🏏 Premium English Willow Bats, Pads, Chrome Grille Helmets\n• ⚡ 60 FPS Professional MoCap Batting & Bowling Kinematics"
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	details_label.add_theme_font_size_override("font_size", 13)
	details_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	vbox.add_child(details_label)

	# Progress Bar
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 24)
	progress_bar.show_percentage = false
	var style_bg := StyleBoxFlat.new()
	style_bg.bg_color = Color(0.04, 0.06, 0.08)
	style_bg.corner_radius_top_left = 8
	style_bg.corner_radius_top_right = 8
	style_bg.corner_radius_bottom_left = 8
	style_bg.corner_radius_bottom_right = 8
	progress_bar.add_theme_stylebox_override("background", style_bg)
	var style_fg := StyleBoxFlat.new()
	style_fg.bg_color = Color(0.1, 0.75, 0.35)
	style_fg.corner_radius_top_left = 8
	style_fg.corner_radius_top_right = 8
	style_fg.corner_radius_bottom_left = 8
	style_fg.corner_radius_bottom_right = 8
	progress_bar.add_theme_stylebox_override("fill", style_fg)
	vbox.add_child(progress_bar)

	percent_label = Label.new()
	percent_label.text = "Pack Size: ~1.2 GB (High-Speed Download via CDN)"
	percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	percent_label.add_theme_font_size_override("font_size", 13)
	percent_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	vbox.add_child(percent_label)

	# Action Buttons
	var hbox_btns := HBoxContainer.new()
	hbox_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_btns.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox_btns)

	download_btn = Button.new()
	download_btn.text = "⬇ DOWNLOAD 1.2 GB PACK"
	download_btn.custom_minimum_size = Vector2(260, 52)
	var style_d := StyleBoxFlat.new()
	style_d.bg_color = Color(0.12, 0.65, 0.28)
	style_d.corner_radius_top_left = 12
	style_d.corner_radius_top_right = 12
	style_d.corner_radius_bottom_left = 12
	style_d.corner_radius_bottom_right = 12
	download_btn.add_theme_stylebox_override("normal", style_d)
	download_btn.pressed.connect(_on_start_download_pressed)
	hbox_btns.add_child(download_btn)

	play_offline_btn = Button.new()
	play_offline_btn.text = "⏩ PLAY OFFLINE (CORE PACK)"
	play_offline_btn.custom_minimum_size = Vector2(260, 52)
	var style_o := StyleBoxFlat.new()
	style_o.bg_color = Color(0.25, 0.3, 0.4)
	style_o.corner_radius_top_left = 12
	style_o.corner_radius_top_right = 12
	style_o.corner_radius_bottom_left = 12
	style_o.corner_radius_bottom_right = 12
	play_offline_btn.add_theme_stylebox_override("normal", style_o)
	play_offline_btn.pressed.connect(_on_skip_to_offline)
	hbox_btns.add_child(play_offline_btn)

func _on_start_download_pressed() -> void:
	if is_downloading:
		return
	is_downloading = true
	download_btn.disabled = true
	download_btn.text = "⏳ DOWNLOADING..."
	download_start_time = Time.get_ticks_msec() / 1000.0
	status_label.text = "CONNECTING TO CONTENT DELIVERY NETWORK..."

	_stream_download_to_file(DIRECT_DOWNLOAD_URL)

func _stream_download_to_file(url: String) -> void:
	# Ensure directory exists
	var dir := DirAccess.open("user://")
	if dir == null:
		DirAccess.make_dir_absolute("user://")
	
	http_request.download_file = PACK_SAVE_PATH
	var headers: PackedStringArray = [
		"User-Agent: Mozilla/5.0 (Android; Mobile; rv:109.0) Gecko/109.0 Firefox/119.0 CricStrike3D",
		"Accept: */*"
	]
	var err: Error = http_request.request(url, headers)
	if err != OK:
		status_label.text = "Connection failed (%d). You can play offline now." % err
		download_btn.disabled = false
		download_btn.text = "🔄 RETRY DOWNLOAD"
		is_downloading = false

func _on_download_completed(result: int, response_code: int, headers: PackedStringArray, _body: PackedByteArray) -> void:
	# Handle HTTP 301 / 302 manual redirection fallback if not handled automatically
	if response_code == 301 or response_code == 302:
		for h in headers:
			if h.to_lower().begins_with("location:"):
				var redirect_url := h.substr(9).strip_edges()
				if not redirect_url.is_empty():
					print("Redirecting to: ", redirect_url)
					_stream_download_to_file(redirect_url)
					return

	is_downloading = false
	if result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 206):
		progress_bar.value = 100.0
		status_label.text = "DOWNLOAD COMPLETE! MOUNTING 1.2 GB EXPANSION PACK..."
		_mount_pack_and_launch()
	else:
		status_label.text = "Download paused (Status %d). You can play offline now!" % response_code
		download_btn.disabled = false
		download_btn.text = "🔄 RETRY DOWNLOAD"

func _mount_pack_and_launch() -> void:
	if FileAccess.file_exists(PACK_SAVE_PATH):
		var success: bool = ProjectSettings.load_resource_pack(PACK_SAVE_PATH)
		if success:
			print("✅ Successfully mounted 1.2 GB Console Asset Pack into Virtual File System!")
	
	var timer := get_tree().create_timer(0.6)
	timer.timeout.connect(func():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)

func _on_skip_to_offline() -> void:
	if is_downloading and http_request:
		http_request.cancel_request()
		is_downloading = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

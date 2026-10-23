# scripts/core/audio_manager.gd
# Procedural Audio & Dynamic Crowd Atmosphere Engine for CricStrike 3D
# Generates realistic physical sounds (bat crack, bounce, stumps, crowd) via AudioStreamWAV synthesis.
extends Node

var sfx_players: Array[AudioStreamPlayer] = []
var crowd_loop_player: AudioStreamPlayer
var commentary_player: AudioStreamPlayer

var snd_bat_sweetspot: AudioStreamWAV
var snd_bat_edge: AudioStreamWAV
var snd_ball_bounce: AudioStreamWAV
var snd_stump_shatter: AudioStreamWAV
var snd_crowd_cheer: AudioStreamWAV
var snd_crowd_gasp: AudioStreamWAV
var snd_applause: AudioStreamWAV
var snd_drs_beep: AudioStreamWAV
var snd_umpire_whistle: AudioStreamWAV
var snd_ui_click: AudioStreamWAV

func _ready() -> void:
	_init_audio_channels()
	_synthesize_all_sfx()
	start_ambient_crowd()

func _init_audio_channels() -> void:
	for i in range(8):
		var p = AudioStreamPlayer.new()
		p.name = "SFXPlayer_" + str(i)
		add_child(p)
		sfx_players.append(p)
	
	crowd_loop_player = AudioStreamPlayer.new()
	crowd_loop_player.name = "CrowdAmbiance"
	crowd_loop_player.volume_db = -12.0
	add_child(crowd_loop_player)
	
	commentary_player = AudioStreamPlayer.new()
	commentary_player.name = "CommentaryAudio"
	commentary_player.volume_db = 0.0
	add_child(commentary_player)

func _get_free_player() -> AudioStreamPlayer:
	for p in sfx_players:
		if not p.playing:
			return p
	return sfx_players[0]

func play_bat_crack(is_sweetspot: bool = true) -> void:
	var p = _get_free_player()
	p.stream = snd_bat_sweetspot if is_sweetspot else snd_bat_edge
	p.volume_db = 2.0 if is_sweetspot else -2.0
	p.pitch_scale = randf_range(0.96, 1.04)
	p.play()

func play_ball_bounce() -> void:
	var p = _get_free_player()
	p.stream = snd_ball_bounce
	p.volume_db = -1.0
	p.pitch_scale = randf_range(0.92, 1.08)
	p.play()

func play_stump_shatter() -> void:
	var p = _get_free_player()
	p.stream = snd_stump_shatter
	p.volume_db = 4.0
	p.play()
	trigger_crowd_cheer(true)

func trigger_crowd_cheer(explosive: bool = false) -> void:
	var p = _get_free_player()
	p.stream = snd_crowd_cheer
	p.volume_db = 3.0 if explosive else 0.0
	p.pitch_scale = randf_range(0.95, 1.05)
	p.play()

func trigger_crowd_gasp() -> void:
	var p = _get_free_player()
	p.stream = snd_crowd_gasp
	p.volume_db = 1.0
	p.play()

func trigger_applause() -> void:
	var p = _get_free_player()
	p.stream = snd_applause
	p.volume_db = 2.0
	p.play()

func play_drs_beep() -> void:
	var p = _get_free_player()
	p.stream = snd_drs_beep
	p.volume_db = 0.0
	p.play()

func play_whistle() -> void:
	var p = _get_free_player()
	p.stream = snd_umpire_whistle
	p.volume_db = 1.0
	p.play()

func play_ui_click() -> void:
	var p = _get_free_player()
	p.stream = snd_ui_click
	p.volume_db = -4.0
	p.pitch_scale = randf_range(0.98, 1.02)
	p.play()

func start_ambient_crowd() -> void:
	# Generate 4-second seamless crowd murmur loop
	var sample_rate = 22050
	var duration = 4.0
	var total_samples = int(sample_rate * duration)
	var byte_array = PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	var last_val = 0.0
	for i in range(total_samples):
		var white_noise = (randf() * 2.0 - 1.0) * 0.15
		# Low-pass filter for stadium drone / murmur
		last_val = lerp(last_val, white_noise, 0.08)
		# Slow gentle modulation
		var mod = (sin(i * 0.002) * 0.3 + 0.7)
		var sample_val = clampf(last_val * mod, -1.0, 1.0)
		var int_val = int(sample_val * 32767.0)
		byte_array.encode_s16(i * 2, int_val)
	
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total_samples
	stream.data = byte_array
	
	crowd_loop_player.stream = stream
	crowd_loop_player.play()

# ----------------- PROCEDURAL AUDIO SYNTHESIZERS -----------------

func _synthesize_all_sfx() -> void:
	snd_bat_sweetspot = _create_bat_crack(2600.0, 0.14, 0.95)
	snd_bat_edge = _create_bat_crack(3400.0, 0.09, 0.60)
	snd_ball_bounce = _create_ball_bounce()
	snd_stump_shatter = _create_stump_shatter()
	snd_crowd_cheer = _create_crowd_roar(2.8)
	snd_crowd_gasp = _create_crowd_gasp()
	snd_applause = _create_applause(3.0)
	snd_drs_beep = _create_tone(1200.0, 0.12)
	snd_umpire_whistle = _create_whistle()
	snd_ui_click = _create_tone(880.0, 0.04)

func _create_bat_crack(freq: float, duration: float, hardness: float) -> AudioStreamWAV:
	var sample_rate = 44100
	var total_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * (45.0 - hardness * 15.0))
		# High frequency wood impulse combined with sweetspot resonance
		var wood_res = sin(TAU * freq * t) * 0.5 + sin(TAU * (freq * 0.45) * t) * 0.3
		var noise = (randf() * 2.0 - 1.0) * exp(-t * 120.0) * 0.6
		var val = clampf((wood_res * 0.6 + noise) * env, -1.0, 1.0)
		bytes.encode_s16(i * 2, int(val * 32767.0))
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = bytes
	return wav

func _create_ball_bounce() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.18
	var total_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / sample_rate
		# Pitch drop from 160Hz to 45Hz
		var current_freq = lerp(160.0, 45.0, t / duration)
		var env = exp(-t * 28.0)
		var val = sin(TAU * current_freq * t) * env
		bytes.encode_s16(i * 2, int(clampf(val, -1.0, 1.0) * 32767.0))
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = bytes
	return wav

func _create_stump_shatter() -> AudioStreamWAV:
	var sample_rate = 44100
	var duration = 0.55
	var total_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 14.0)
		# Clattering wood elements: 3 wooden poles rattling together
		var w1 = sin(TAU * 720.0 * t) * exp(-t * 20.0)
		var w2 = sin(TAU * 1150.0 * t) * exp(-t * 26.0)
		var clatter = (randf() * 2.0 - 1.0) * exp(-t * 35.0) * 0.7
		var val = (w1 * 0.4 + w2 * 0.4 + clatter) * env
		bytes.encode_s16(i * 2, int(clampf(val, -1.0, 1.0) * 32767.0))
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = bytes
	return wav

func _create_crowd_roar(duration: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var total_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples * 2)
	
	var last_noise = 0.0
	for i in range(total_samples):
		var t = float(i) / sample_rate
		# Rise sharply then sustain and fade
		var env = 0.0
		if t < 0.4:
			env = t / 0.4
		elif t < duration * 0.7:
			env = 1.0
		else:
			env = maxf(0.0, 1.0 - (t - duration * 0.7) / (duration * 0.3))
		
		var raw_noise = (randf() * 2.0 - 1.0)
		last_noise = lerp(last_noise, raw_noise, 0.12)
		var val = last_noise * env * 0.85
		bytes.encode_s16(i * 2, int(clampf(val, -1.0, 1.0) * 32767.0))
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = bytes
	return wav

func _create_crowd_gasp() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.85
	var total_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples * 2)
	
	var filtered = 0.0
	for i in range(total_samples):
		var t = float(i) / sample_rate
		var env = sin((t / duration) * PI)
		var noise = (randf() * 2.0 - 1.0)
		filtered = lerp(filtered, noise, 0.09)
		var val = filtered * env * 0.7
		bytes.encode_s16(i * 2, int(clampf(val, -1.0, 1.0) * 32767.0))
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = bytes
	return wav

func _create_applause(duration: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var total_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples * 2)
	
	var claps = []
	for c in range(120):
		claps.append(randf_range(0.0, duration))
	
	for i in range(total_samples):
		var t = float(i) / sample_rate
		var val = 0.0
		for clap_time in claps:
			var dt = t - clap_time
			if dt >= 0.0 and dt < 0.025:
				val += (randf() * 2.0 - 1.0) * exp(-dt * 150.0) * 0.15
		var master_env = sin((t / duration) * PI)
		bytes.encode_s16(i * 2, int(clampf(val * master_env, -1.0, 1.0) * 32767.0))
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = bytes
	return wav

func _create_whistle() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.35
	var total_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / sample_rate
		var f1 = 2400.0 + sin(TAU * 35.0 * t) * 60.0
		var f2 = 2850.0 + sin(TAU * 40.0 * t) * 60.0
		var env = minf(t / 0.03, 1.0) * exp(-t * 4.0)
		var val = (sin(TAU * f1 * t) * 0.45 + sin(TAU * f2 * t) * 0.45) * env
		bytes.encode_s16(i * 2, int(clampf(val, -1.0, 1.0) * 32767.0))
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = bytes
	return wav

func _create_tone(freq: float, duration: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var total_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 20.0)
		var val = sin(TAU * freq * t) * env * 0.6
		bytes.encode_s16(i * 2, int(clampf(val, -1.0, 1.0) * 32767.0))
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = bytes
	return wav

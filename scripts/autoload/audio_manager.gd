extends Node

# AudioManager: Procedural Audio Synthesizer & Dynamic Multi-Line Commentary Engine

signal commentary_updated(text: String, tag: String)

var sound_players: Dictionary = {}
var crowd_ambient_player: AudioStreamPlayer
var commentary_queue: Array[Dictionary] = []

const COMMENTARY_LINES: Dictionary = {
	"FOUR": [
		"Crunched through the covers! What a glorious boundary!",
		"Deft touch and it races away past third man for four!",
		"Smashed down the ground! The outfield is lightning fast!",
		"Flayed off the back foot, piercing the inner ring with supreme timing!",
		"Pure timing, pure elegance! Finds the gap effortlessly!",
		"Whipped off the pads with wrists of steel! Four more added to the tally!",
		"Cut away fiercely past point! No fielder had a prayer there!",
		"Inside-out over extra cover! Exquisite piece of batsmanship!"
	],
	"SIX": [
		"Smacked straight down the ground for a maximum! That is massive!",
		"In the slot and dispatched into the top tier! Monstrous hit!",
		"High, handsome, and into orbit! That has cleared the stadium roof!",
		"Helicopter shot! Wristy power sends it sailing into the cow corner stands!",
		"Picked up off his hips and deposited ten rows back over square leg!",
		"Dancing down the track and launching it clean over long-off!",
		"Audacious strike! That ball is still traveling!",
		"Stand and deliver! Clean as a whistle into the pavilion crowd!"
	],
	"BOWLED": [
		"Timber! Clean bowled through the gate! Absolute peach of a delivery!",
		"Cartwheeling leg stump! Express pace shatters the furniture!",
		"Knocked him over! The batsman had no clue about that seam movement!",
		"He's played all around that! Off-stump plucked out of the turf!",
		"Yorker right in the blockhole! You cannot play those at this speed!"
	],
	"CAUGHT": [
		"In the air... and it's taken in the deep! Superb running catch on the boundary!",
		"Edged and taken cleanly by the wicketkeeper! Regulation take behind the stumps!",
		"Thick outside edge flies to first slip, snapped up like a hawk!",
		"Mistimed lofted drive, fielder under it... makes no mistake!",
		"Diving forward at mid-wicket! Unbelievable athleticism, what a catch!"
	],
	"LBW": [
		"Huge appeal for LBW! Up goes the finger from the umpire!",
		"Trapped right in front of all three! Plumb as you like!",
		"Struck on the front pad in line with middle and off! Golden decision!"
	],
	"DOT": [
		"Beaten all ends up! Superb delivery outside off stump.",
		"Solid forward defense right right under the batsman's eyes.",
		"Bangs it in short, batsman ducks comfortably underneath.",
		"Tightly bowled into the channel, dabbed straight to backward point.",
		"Pushed to mid-off, no run conceded. Excellent pressure building."
	],
	"MAIDEN": [
		"Six pristine deliveries! That is a high-class maiden over!",
		"Chokehold bowling from the speedster! Not a single run leaked!"
	],
	"FIFTY": [
		"A masterclass half-century! Raises the bat to roaring applause from the dugout!",
		"Fifty off the highest order! Pure authority and composure under pressure!"
	],
	"CENTURY": [
		"A sensational HUNDRED! Takes off his helmet and soaks in the standing ovation!",
		"One for the ages! A magnificent century crafted with grit and brilliance!"
	],
	"TENSE_FINISH": [
		"Nail-biting tension here in the final over! Every ball is gold dust!",
		"Calculated aggression needed now! Hearts pounding across the stadium!"
	]
}

func _ready() -> void:
	_init_procedural_sounds()
	_init_ambient_loop()

func _init_procedural_sounds() -> void:
	sound_players["bat_crack"] = _create_player(_generate_bat_crack_wav())
	sound_players["ball_bounce"] = _create_player(_generate_ball_bounce_wav())
	sound_players["stumps_rattle"] = _create_player(_generate_stump_rattle_wav())
	sound_players["crowd_cheer"] = _create_player(_generate_crowd_cheer_wav(2.0, true))
	sound_players["crowd_gasp"] = _create_player(_generate_crowd_gasp_wav())
	sound_players["applause"] = _create_player(_generate_applause_wav())

func _init_ambient_loop() -> void:
	crowd_ambient_player = AudioStreamPlayer.new()
	crowd_ambient_player.stream = _generate_ambient_murmur_wav()
	crowd_ambient_player.volume_db = -12.0
	crowd_ambient_player.autoplay = true
	add_child(crowd_ambient_player)

func _create_player(stream: AudioStreamWAV) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	return player

func play_sfx(sfx_name: String, pitch_scale: float = 1.0) -> void:
	if sound_players.has(sfx_name):
		var p: AudioStreamPlayer = sound_players[sfx_name]
		p.pitch_scale = pitch_scale
		p.play()

func trigger_commentary(category: String, custom_line: String = "") -> void:
	var text: String = custom_line
	if text.is_empty() and COMMENTARY_LINES.has(category):
		var list: Array = COMMENTARY_LINES[category]
		text = list[randi() % list.size()]
	
	if not text.is_empty():
		commentary_updated.emit(text, category)

# --- Procedural Audio Synthesizers (PCM 16-bit Mono @ 22050Hz) ---

func _generate_bat_crack_wav() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.22
	var total_samples: int = int(sample_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)

	for i in range(total_samples):
		var t: float = float(i) / sample_rate
		# Crisp English willow resonant impact: dual high Q sinusoid + sharp noise burst
		var decay: float = exp(-t * 32.0)
		var freq1: float = 1450.0
		var freq2: float = 2850.0
		var wood_osc: float = sin(t * freq1 * TAU) * 0.6 + sin(t * freq2 * TAU) * 0.4
		var snap_noise: float = (randf() * 2.0 - 1.0) * exp(-t * 90.0) * 0.7
		var sample_val: float = clamp((wood_osc * decay + snap_noise) * 0.85, -1.0, 1.0)
		var int16: int = int(sample_val * 32767.0)
		byte_array.encode_s16(i * 2, int16)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = byte_array
	return wav

func _generate_ball_bounce_wav() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.16
	var total_samples: int = int(sample_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)

	for i in range(total_samples):
		var t: float = float(i) / sample_rate
		var decay: float = exp(-t * 28.0)
		# Deep turf thud pitch swept down from 240Hz to 80Hz
		var current_freq: float = lerp(260.0, 75.0, min(t * 12.0, 1.0))
		var thud: float = sin(t * current_freq * TAU) * decay
		var sample_val: float = clamp(thud * 0.9, -1.0, 1.0)
		var int16: int = int(sample_val * 32767.0)
		byte_array.encode_s16(i * 2, int16)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = byte_array
	return wav

func _generate_stump_rattle_wav() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.45
	var total_samples: int = int(sample_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)

	for i in range(total_samples):
		var t: float = float(i) / sample_rate
		# Multi-wood transient strikes simulating stumps & bails flying
		var s1: float = sin(t * 920.0 * TAU) * exp(-t * 18.0)
		var s2: float = sin((t - 0.04) * 1350.0 * TAU) * exp(-max(t - 0.04, 0.0) * 22.0) if t > 0.04 else 0.0
		var s3: float = sin((t - 0.09) * 2100.0 * TAU) * exp(-max(t - 0.09, 0.0) * 30.0) if t > 0.09 else 0.0
		var wood_clatter: float = s1 * 0.5 + s2 * 0.35 + s3 * 0.25
		var sample_val: float = clamp(wood_clatter * 0.95, -1.0, 1.0)
		var int16: int = int(sample_val * 32767.0)
		byte_array.encode_s16(i * 2, int16)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = byte_array
	return wav

func _generate_crowd_cheer_wav(duration: float, explosive: bool) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(sample_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)

	var filter_state: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / sample_rate
		# Envelope swell
		var env: float = 0.0
		if explosive:
			env = (1.0 - exp(-t * 12.0)) * exp(-t * 1.2)
		else:
			env = sin((t / duration) * PI)
		
		# Pink-like filtered random noise
		var white: float = randf() * 2.0 - 1.0
		filter_state = filter_state * 0.88 + white * 0.12
		var cheer: float = filter_state * env * 0.8
		var int16: int = int(clamp(cheer, -1.0, 1.0) * 32767.0)
		byte_array.encode_s16(i * 2, int16)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = byte_array
	return wav

func _generate_crowd_gasp_wav() -> AudioStreamWAV:
	return _generate_crowd_cheer_wav(0.8, false)

func _generate_applause_wav() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 2.5
	var total_samples: int = int(sample_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)

	for i in range(total_samples):
		var t: float = float(i) / sample_rate
		var env: float = sin((t / duration) * PI)
		# Scattered claps
		var clap: float = 0.0
		if randf() < 0.04:
			clap = (randf() * 2.0 - 1.0) * 0.8
		var val: float = clamp(clap * env, -1.0, 1.0)
		byte_array.encode_s16(i * 2, int(val * 32767.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.data = byte_array
	return wav

func _generate_ambient_murmur_wav() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 3.0
	var total_samples: int = int(sample_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)

	var filter_val: float = 0.0
	for i in range(total_samples):
		var white: float = randf() * 2.0 - 1.0
		filter_val = filter_val * 0.94 + white * 0.06
		var val: float = clamp(filter_val * 0.25, -1.0, 1.0)
		byte_array.encode_s16(i * 2, int(val * 32767.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.data = byte_array
	return wav

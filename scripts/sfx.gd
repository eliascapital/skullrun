extends Node
## Tiny retro sound effects generated in code (no audio files needed).
## Usage: Sfx.play("jump")

const MIX_RATE := 22050
const VOICES := 8

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.volume_db = -8.0
		add_child(p)
		_players.append(p)
	# name: [start Hz, end Hz, seconds, wave, volume]
	_streams["jump"] = _make([[320, 640, 0.12, "square", 0.25]])
	_streams["double_jump"] = _make([[480, 960, 0.12, "square", 0.22]])
	_streams["dash"] = _make([[900, 200, 0.14, "noise", 0.25]])
	_streams["gem"] = _make([[880, 880, 0.06, "square", 0.2], [1320, 1320, 0.1, "square", 0.2]])
	_streams["death"] = _make([[400, 60, 0.4, "saw", 0.3], [100, 40, 0.2, "noise", 0.3]])
	_streams["checkpoint"] = _make([[523, 523, 0.08, "triangle", 0.35], [659, 659, 0.08, "triangle", 0.35], [784, 784, 0.16, "triangle", 0.35]])
	_streams["stomp"] = _make([[300, 80, 0.12, "noise", 0.3], [220, 440, 0.08, "square", 0.2]])
	_streams["bounce"] = _make([[200, 900, 0.2, "triangle", 0.4]])
	_streams["crumble"] = _make([[180, 60, 0.25, "noise", 0.2]])
	_streams["win"] = _make([[523, 523, 0.1, "square", 0.2], [659, 659, 0.1, "square", 0.2], [784, 784, 0.1, "square", 0.2], [1046, 1046, 0.3, "square", 0.2]])
	_streams["click"] = _make([[660, 660, 0.04, "square", 0.15]])
	_streams["hover"] = _make([[440, 440, 0.025, "triangle", 0.12]])


func play(sound: String, pitch: float = 1.0) -> void:
	if not _streams.has(sound):
		return
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _streams[sound]
	p.pitch_scale = pitch
	p.play()


func _make(parts: Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	for part in parts:
		var f0: float = part[0]
		var f1: float = part[1]
		var dur: float = part[2]
		var wave: String = part[3]
		var vol: float = part[4]
		var n := int(dur * MIX_RATE)
		for i in n:
			var t := float(i) / n
			var freq := lerpf(f0, f1, t)
			phase = fmod(phase + freq / MIX_RATE, 1.0)
			var s := 0.0
			match wave:
				"square":
					s = 1.0 if phase < 0.5 else -1.0
				"triangle":
					s = 4.0 * absf(phase - 0.5) - 1.0
				"saw":
					s = 2.0 * phase - 1.0
				"noise":
					s = rng.randf_range(-1.0, 1.0)
			# quick attack, smooth release
			var env := minf(1.0, t * 40.0) * (1.0 - t) * (1.0 - t)
			var v := int(clampf(s * vol * env, -1.0, 1.0) * 32767.0)
			data.append(v & 0xFF)
			data.append((v >> 8) & 0xFF)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream

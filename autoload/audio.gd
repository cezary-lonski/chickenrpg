extends Node
## Audio — cała oprawa dźwiękowa generowana proceduralnie (zero plików).
## SFX to krótkie przebiegi zsyntezowane z sinusów, pięt i szumu. Muzyka to
## średniowieczny loop: lutnia, flet, burdon i bęben obręczowy.

const MIX := 22050
const SFX_POOL := 12
const VOICES := 8

var _sfx: Dictionary = {}
var _music: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _next_voice: int = 0
var _current_track := ""
var _rng := RandomNumberGenerator.new()
var _warm_thread: Thread
var _voice: Array = []
var _voice_token := 0

# ------------------------------------------------------------------ tablice ---

var _hits := [55.0, 61.0, 66.0, 73.0, 82.0, 92.0, 110.0, 123.0, 146.0, 165.0, 185.0, 220.0]

const MODES := {
	"dorian": [0, 2, 3, 5, 7, 9, 10],
	"phrygian": [0, 1, 3, 5, 7, 8, 10],
	"aeolian": [0, 2, 3, 5, 7, 8, 10],
	"mixolydian": [0, 2, 4, 5, 7, 9, 10],
	"ionian": [0, 2, 4, 5, 7, 9, 11],
	"lydian": [0, 2, 4, 6, 7, 9, 11],
	"harmonic": [0, 2, 3, 5, 7, 8, 11],
}

## prog = stopnie skali (podstawa akordu) dla każdego z 8 taktów; drums 0-2
const THEMES := {
	"menu": {"bpm": 82.0, "root": 0, "mode": "dorian", "prog": [0, 0, 6, 6, 3, 3, 4, 0], "lead": "flute", "arp": true, "drums": 0},
	"podworko": {"bpm": 112.0, "root": 5, "mode": "mixolydian", "prog": [0, 0, 3, 0, 0, 3, 6, 0], "lead": "flute", "arp": true, "drums": 1},
	"sad": {"bpm": 104.0, "root": 7, "mode": "ionian", "prog": [0, 3, 4, 0, 0, 3, 4, 0], "lead": "pluck", "arp": true, "drums": 1},
	"las": {"bpm": 92.0, "root": 3, "mode": "dorian", "prog": [0, 0, 6, 6, 3, 3, 0, 4], "lead": "flute", "arp": true, "drums": 0},
	"zagroda": {"bpm": 96.0, "root": 10, "mode": "ionian", "prog": [0, 0, 3, 3, 4, 4, 0, 0], "lead": "pluck", "arp": true, "drums": 1},
	"polana": {"bpm": 88.0, "root": 8, "mode": "lydian", "prog": [0, 4, 3, 0, 0, 4, 3, 0], "lead": "flute", "arp": true, "drums": 0},
	"mlyn": {"bpm": 126.0, "root": 8, "mode": "mixolydian", "prog": [0, 3, 0, 4, 0, 3, 4, 0], "lead": "pluck", "arp": true, "drums": 1},
	"krolestwo": {"bpm": 96.0, "root": 7, "mode": "dorian", "prog": [0, 3, 4, 0, 6, 3, 4, 0], "lead": "flute", "arp": true, "drums": 2},
	"stodola": {"bpm": 120.0, "root": 9, "mode": "aeolian", "prog": [0, 0, 5, 5, 6, 6, 0, 0], "lead": "pluck", "arp": true, "drums": 2},
	"bagno": {"bpm": 76.0, "root": 0, "mode": "phrygian", "prog": [0, 0, 1, 1, 0, 0, 3, 4], "lead": "flute", "arp": false, "drums": 1},
	"gniazdo": {"bpm": 138.0, "root": 4, "mode": "harmonic", "prog": [0, 0, 4, 4, 5, 5, 4, 0], "lead": "pluck", "arp": true, "drums": 2},
	"boss": {"bpm": 132.0, "root": 2, "mode": "phrygian", "prog": [0, 0, 1, 0, 0, 1, 6, 0], "lead": "pluck", "arp": true, "drums": 2},
	"ep_wies": {"bpm": 76.0, "root": 7, "mode": "ionian", "prog": [0, 3, 4, 0, 3, 4, 0, 0], "lead": "pluck", "arp": true, "drums": 0},
	"ep_stolica": {"bpm": 68.0, "root": 2, "mode": "aeolian", "prog": [0, 5, 3, 4, 0, 5, 4, 0], "lead": "flute", "arp": false, "drums": 0},
	"ep_kruk": {"bpm": 84.0, "root": 9, "mode": "harmonic", "prog": [0, 0, 5, 4, 0, 0, 5, 0], "lead": "pluck", "arp": true, "drums": 1},
	"ep_krol": {"bpm": 90.0, "root": 0, "mode": "ionian", "prog": [0, 4, 5, 3, 0, 4, 3, 0], "lead": "flute", "arp": true, "drums": 0},
	"ep_miasto": {"bpm": 80.0, "root": 5, "mode": "dorian", "prog": [0, 0, 3, 6, 0, 3, 4, 0], "lead": "pluck", "arp": true, "drums": 1},
	"ep_zamek": {"bpm": 72.0, "root": 3, "mode": "dorian", "prog": [0, 3, 4, 0, 6, 3, 4, 0], "lead": "flute", "arp": true, "drums": 1},
	"ep_swit": {"bpm": 84.0, "root": 8, "mode": "lydian", "prog": [0, 4, 3, 0, 0, 4, 3, 0], "lead": "flute", "arp": true, "drums": 0},
	"fin_a": {"bpm": 66.0, "root": 7, "mode": "ionian", "prog": [0, 3, 4, 0, 3, 4, 0, 0], "lead": "flute", "arp": true, "drums": 0},
	"fin_b": {"bpm": 98.0, "root": 0, "mode": "ionian", "prog": [0, 4, 5, 3, 0, 4, 3, 0], "lead": "flute", "arp": true, "drums": 2},
	"fin_c": {"bpm": 62.0, "root": 5, "mode": "lydian", "prog": [0, 4, 3, 0, 0, 4, 3, 0], "lead": "flute", "arp": true, "drums": 0},
	"victory": {"bpm": 116.0, "root": 5, "mode": "ionian", "prog": [0, 3, 4, 0, 3, 4, 0, 0], "lead": "flute", "arp": true, "drums": 2},
}

# --------------------------------------------------------------------- API ---

func _ready() -> void:
	_rng.seed = 1337
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in SFX_POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_pool.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.volume_db = -13.0
	add_child(_music_player)
	_build_sfx()
	_warm_thread = Thread.new()
	_warm_thread.start(_warm_music)

func play(name: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not GameState.setting("sfx"):
		return
	if not _sfx.has(name):
		return
	var p: AudioStreamPlayer = _pool[_next_voice % _pool.size()]
	_next_voice += 1
	p.stream = _sfx[name]
	p.pitch_scale = clampf(pitch, 0.4, 2.5)
	p.volume_db = volume_db
	p.play()

## Utwory budują się w tle zaraz po starcie, żeby pierwsze odtworzenie nie zacinało gry.
func _warm_music() -> void:
	for t in THEMES.keys():
		var st := _build_music(String(t))
		_store_music.call_deferred(String(t), st)

func _store_music(track: String, st: AudioStreamWAV) -> void:
	if not _music.has(track):
		_music[track] = st

func _exit_tree() -> void:
	if _warm_thread != null and _warm_thread.is_started():
		_warm_thread.wait_to_finish()

## Głos postaci w dialogach: seria gdakań z nagrania, wysokość zależy od mówiącego.
func speak(who: String, text: String) -> void:
	_voice_token += 1
	if who == "" or not GameState.setting("sfx"):
		return
	if _voice.is_empty():
		for i in range(1, 13):
			var st = load("res://audio/voice/gdak_%02d.wav" % i)
			if st != null:
				_voice.append(st)
	if _voice.is_empty():
		return
	var token := _voice_token
	var pitch := 0.75 + float(absi(hash(who)) % 100) / 100.0 * 0.8
	var n := clampi(int(float(text.length()) / 7.0), 2, 9)
	for i in n:
		if token != _voice_token:
			return
		var p: AudioStreamPlayer = _pool[_next_voice % _pool.size()]
		_next_voice += 1
		p.stream = _voice[_rng.randi_range(0, _voice.size() - 1)]
		p.pitch_scale = pitch * _rng.randf_range(0.92, 1.1)
		p.volume_db = -3.0
		p.play()
		await get_tree().create_timer(_rng.randf_range(0.16, 0.24), true, false, true).timeout

func stop_speaking() -> void:
	_voice_token += 1

func play_music(track: String) -> void:
	if _current_track == track and _music_player.playing:
		return
	_current_track = track
	if not GameState.setting("music") or track == "":
		_music_player.stop()
		return
	if not _music.has(track):
		_music[track] = _build_music(track)
	_music_player.stream = _music[track]
	_music_player.play()

func current_track() -> String:
	return _current_track

func stop_music() -> void:
	_current_track = ""
	_music_player.stop()

func set_music_enabled(on: bool) -> void:
	if not on:
		_music_player.stop()
	elif _current_track != "":
		var t := _current_track
		_current_track = ""
		play_music(t)

# -------------------------------------------------------------- generatory ---

func _osc(kind: String, phase: float) -> float:
	var p := fposmod(phase, 1.0)
	match kind:
		"square":
			return 1.0 if p < 0.5 else -1.0
		"pulse":
			return 1.0 if p < 0.25 else -1.0
		"saw":
			return p * 2.0 - 1.0
		"tri":
			return 1.0 - 4.0 * absf(p - 0.5)
		_:
			return sin(p * TAU)

func _env(i: int, n: int, atk: float, dec: float, curve: float = 1.0) -> float:
	var t := float(i) / float(maxi(1, n))
	var a := maxf(0.001, atk)
	if t < a:
		return t / a
	var d := (t - a) / maxf(0.001, 1.0 - a)
	return pow(maxf(0.0, 1.0 - d), curve) * (1.0 - d * 0.15)

func _to_stream(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = MIX
	st.stereo = false
	st.data = data
	if loop:
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = samples.size()
	return st

func _n(dur: float) -> int:
	return int(dur * float(MIX))

# -------------------------------------------------------------------- SFX ---

func _build_sfx() -> void:
	_sfx = {
		"swing": _mk_swing(),
		"swing_heavy": _mk_swing_heavy(),
		"swing_weapon": _mk_swing_weapon(),
		"swing_heavy_weapon": _mk_swing_heavy_weapon(),
		"hit": _mk_hit(0.16, 0.55, 900.0),
		"hit_heavy": _mk_hit(0.3, 0.85, 1500.0),
		"hit_crit": _mk_hit(0.26, 0.95, 2400.0),
		"hurt": _mk_hurt(),
		"jump": _mk_jump(),
		"land": _mk_land(),
		"dash": _mk_dash(),
		"block": _mk_block(),
		"parry": _mk_parry(),
		"coin": _mk_coin(),
		"levelup": _mk_levelup(),
		"egg": _mk_egg(),
		"throw": _mk_throw(),
		"explode": _mk_explode(),
		"die": _mk_die(),
		"roar": _mk_roar(),
		"select": _mk_ui(660.0, 0.07, "square"),
		"confirm": _mk_ui(880.0, 0.14, "square"),
		"back": _mk_ui(330.0, 0.12, "square"),
		"deny": _mk_ui(180.0, 0.16, "saw"),
		"equip": _mk_ui(520.0, 0.13, "triangle"),
		"pause": _mk_ui(440.0, 0.1, "square"),
		"gate": _mk_gate(),
		"drink": _mk_drink(),
		"punch": _mk_hit(0.12, 0.4, 500.0),
	}

func _mk_swing() -> AudioStreamWAV:
	var n := _n(0.16)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / float(n)
		ph += (1800.0 - 1300.0 * t) / float(MIX)
		var noise := _rng.randf_range(-1.0, 1.0) * (1.0 - t) * 0.35
		s[i] = (_osc("sine", ph) * 0.25 + noise) * _env(i, n, 0.05, 0.95, 2.0) * 0.5
	return _to_stream(s)

func _mk_swing_heavy() -> AudioStreamWAV:
	var n := _n(0.28)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / float(n)
		ph += (1200.0 - 950.0 * t) / float(MIX)
		s[i] = (_osc("saw", ph) * 0.2 + _rng.randf_range(-1.0, 1.0) * 0.3 * (1.0 - t)) * _env(i, n, 0.1, 0.9, 1.6) * 0.55
	return _to_stream(s)

func _mk_swing_weapon() -> AudioStreamWAV:
	var n := _n(0.15)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / float(n)
		ph += (2400.0 - 1700.0 * t) / float(MIX)
		var noise := _rng.randf_range(-1.0, 1.0) * (1.0 - t) * 0.4
		s[i] = (_osc("sine", ph) * 0.22 + noise) * _env(i, n, 0.04, 0.96, 2.1) * 0.5
	return _to_stream(s)

func _mk_swing_heavy_weapon() -> AudioStreamWAV:
	var n := _n(0.36)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / float(n)
		ph += (950.0 - 780.0 * t) / float(MIX)
		s[i] = (_osc("saw", ph) * 0.22 + _rng.randf_range(-1.0, 1.0) * 0.32 * (1.0 - t)) * _env(i, n, 0.12, 0.88, 1.5) * 0.58
	return _to_stream(s)

func _mk_hit(dur: float, power: float, cut: float) -> AudioStreamWAV:
	var n := _n(dur)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	var ph2 := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / float(n)
		ph += (260.0 - 180.0 * t) / float(MIX)
		ph2 += (110.0 - 70.0 * t) / float(MIX)
		var raw := _rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, raw, clampf(cut / float(MIX) * 12.0, 0.05, 0.9))
		var body := _osc("tri", ph) * 0.5 + _osc("sine", ph2) * 0.6
		s[i] = (body * power + lp * (1.0 - t) * 0.5) * _env(i, n, 0.005, 0.95, 2.4) * 0.85
	return _to_stream(s)

func _mk_hurt() -> AudioStreamWAV:
	var n := _n(0.3)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / float(n)
		ph += (420.0 - 300.0 * t) / float(MIX)
		s[i] = _osc("square", ph) * 0.35 * _env(i, n, 0.01, 0.9, 1.8) * 0.5
	return _to_stream(s)

func _mk_jump() -> AudioStreamWAV:
	var n := _n(0.18)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / float(n)
		ph += (300.0 + 520.0 * t) / float(MIX)
		s[i] = _osc("tri", ph) * 0.45 * _env(i, n, 0.02, 0.98, 1.4) * 0.5
	return _to_stream(s)

func _mk_land() -> AudioStreamWAV:
	var n := _n(0.14)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / float(n)
		ph += (150.0 - 90.0 * t) / float(MIX)
		s[i] = (_osc("sine", ph) * 0.6 + _rng.randf_range(-1.0, 1.0) * 0.15 * (1.0 - t)) * _env(i, n, 0.005, 0.95, 2.5) * 0.5
	return _to_stream(s)

func _mk_dash() -> AudioStreamWAV:
	var n := _n(0.22)
	var s := PackedFloat32Array()
	s.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / float(n)
		lp = lerpf(lp, _rng.randf_range(-1.0, 1.0), 0.06 + 0.25 * (1.0 - t))
		s[i] = lp * _env(i, n, 0.05, 0.95, 1.5) * 0.4
	return _to_stream(s)

func _mk_block() -> AudioStreamWAV:
	var n := _n(0.2)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / float(n)
		s[i] = (_osc("square", 210.0 * float(i) / float(MIX)) * 0.2 + _osc("square", 630.0 * float(i) / float(MIX)) * 0.15 + _rng.randf_range(-1.0, 1.0) * 0.25 * (1.0 - t)) * _env(i, n, 0.004, 0.95, 2.6) * 0.6
	return _to_stream(s)

func _mk_parry() -> AudioStreamWAV:
	var n := _n(0.42)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / float(n)
		var v := 0.0
		for k in 4:
			v += _osc("tri", (880.0 * (1.0 + k * 0.5)) * float(i) / float(MIX)) * (0.3 / float(k + 1))
		s[i] = v * _env(i, n, 0.002, 0.98, 2.0) * 0.55
	return _to_stream(s)

func _mk_coin() -> AudioStreamWAV:
	var n := _n(0.16)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / float(n)
		var f := 1180.0 if t < 0.45 else 1620.0
		s[i] = _osc("square", f * float(i) / float(MIX)) * 0.3 * _env(i, n, 0.004, 0.98, 1.6) * 0.45
	return _to_stream(s)

func _mk_levelup() -> AudioStreamWAV:
	var n := _n(0.75)
	var s := PackedFloat32Array()
	s.resize(n)
	var steps := [523.0, 659.0, 784.0, 1046.0, 1318.0]
	for i in n:
		var t := float(i) / float(n)
		var idx := clampi(int(t * float(steps.size())), 0, steps.size() - 1)
		var f: float = steps[idx]
		s[i] = (_osc("square", f * float(i) / float(MIX)) * 0.3 + _osc("tri", f * 2.0 * float(i) / float(MIX)) * 0.15) * _env(i, n, 0.01, 0.99, 0.6) * 0.5
	return _to_stream(s)

func _mk_egg() -> AudioStreamWAV:
	var n := _n(0.18)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / float(n)
		s[i] = (_osc("square", (600.0 - 350.0 * t) * float(i) / float(MIX)) * 0.35 + _rng.randf_range(-1.0, 1.0) * 0.3 * (1.0 - t)) * _env(i, n, 0.004, 0.95, 2.0) * 0.5
	return _to_stream(s)

func _mk_throw() -> AudioStreamWAV:
	var n := _n(0.22)
	var s := PackedFloat32Array()
	s.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / float(n)
		lp = lerpf(lp, _rng.randf_range(-1.0, 1.0), 0.3 * (1.0 - t) + 0.02)
		s[i] = lp * _env(i, n, 0.02, 0.98, 1.2) * 0.35
	return _to_stream(s)

func _mk_explode() -> AudioStreamWAV:
	var n := _n(0.45)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / float(n)
		ph += (180.0 - 140.0 * t) / float(MIX)
		lp = lerpf(lp, _rng.randf_range(-1.0, 1.0), 0.35 * (1.0 - t))
		s[i] = (_osc("sine", ph) * 0.7 + lp * 0.6) * _env(i, n, 0.003, 0.97, 1.8) * 0.7
	return _to_stream(s)

func _mk_die() -> AudioStreamWAV:
	var n := _n(0.7)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / float(n)
		ph += (520.0 * pow(0.35, t)) / float(MIX)
		s[i] = _osc("saw", ph) * 0.35 * _env(i, n, 0.01, 0.99, 1.0) * 0.5
	return _to_stream(s)

func _mk_roar() -> AudioStreamWAV:
	var n := _n(0.9)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / float(n)
		var wobble := 1.0 + 0.12 * sin(t * 40.0)
		ph += (70.0 * wobble) / float(MIX)
		var grit := _rng.randf_range(-1.0, 1.0) * 0.2
		s[i] = (_osc("saw", ph) * 0.5 + _osc("square", ph * 2.02) * 0.15 + grit) * _env(i, n, 0.08, 0.92, 1.2) * 0.6
	return _to_stream(s)

func _mk_ui(freq: float, dur: float, wave: String) -> AudioStreamWAV:
	var n := _n(dur)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		s[i] = _osc(wave, freq * float(i) / float(MIX)) * 0.28 * _env(i, n, 0.01, 0.99, 1.3) * 0.4
	return _to_stream(s)

func _mk_gate() -> AudioStreamWAV:
	var n := _n(0.5)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / float(n)
		var f := 120.0 + 200.0 * t
		s[i] = (_osc("saw", f * float(i) / float(MIX)) * 0.3 + _rng.randf_range(-1.0, 1.0) * 0.2 * (1.0 - t)) * _env(i, n, 0.05, 0.95, 1.0) * 0.5
	return _to_stream(s)

func _mk_drink() -> AudioStreamWAV:
	var n := _n(0.4)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / float(n)
		ph += (400.0 - 220.0 * t) / float(MIX)
		s[i] = (_osc("tri", ph) * 0.4 + _osc("sine", ph * 0.5) * 0.3) * _env(i, n, 0.05, 0.95, 1.4) * 0.45
	return _to_stream(s)

# ------------------------------------------------------------------ muzyka ---
## Muzyka średniowieczna: tryby kościelne, lutnia (Karplus-Strong), flet,
## burdon, bęben obręczowy i delikatne echo. 8 taktów w pętli.

func _pitch(root_hz: float, mode: Array, deg: int) -> float:
	var oct := floori(float(deg) / 7.0)
	var idx := posmod(deg, 7)
	return root_hz * pow(2.0, float(int(mode[idx]) + 12 * oct) / 12.0)

func _rhythm(r: RandomNumberGenerator) -> Array:
	var out: Array = []
	var left := 16
	var choices := [1, 2, 2, 2, 3, 4]
	while left > 0:
		var d: int = choices[r.randi_range(0, choices.size() - 1)]
		d = mini(d, left)
		out.append(d)
		left -= d
	return out

func _contour(r: RandomNumberGenerator, n: int) -> Array:
	var out: Array = []
	var choices := [-2, -1, -1, 0, 1, 1, 2]
	for i in n:
		out.append(choices[r.randi_range(0, choices.size() - 1)])
	return out

func _build_music(track: String) -> AudioStreamWAV:
	var cfg: Dictionary = THEMES.get(track, THEMES["menu"])
	var e := 60.0 / float(cfg["bpm"]) / 2.0  # ósemka
	var steps := 64
	var total := _n(e * float(steps))
	var s := PackedFloat32Array()
	s.resize(total)
	s.fill(0.0)
	var mode: Array = MODES[String(cfg["mode"])]
	var root_hz := 110.0 * pow(2.0, float(cfg["root"]) / 12.0)
	var prog: Array = cfg["prog"]
	var drums := int(cfg["drums"])
	var flute_lead := String(cfg["lead"]) == "flute"
	var r := RandomNumberGenerator.new()
	r.seed = hash(track)

	# burdon: tonika + kwinta, liczba okresów całkowita => pętla bez trzasku
	var dur_s := float(total) / float(MIX)
	_add_drone(s, snappedf(root_hz * 0.5 * dur_s, 1.0) / dur_s, 0.1)
	_add_drone(s, snappedf(root_hz * 0.75 * dur_s, 1.0) / dur_s, 0.06)

	# bas + arpeggio lutni
	var arp := [0, 2, 4, 2, 0, 2, 4, 2]
	for bar in 8:
		var c: int = int(prog[bar])
		var t0 := _n(e * float(bar * 8))
		_pluck(s, t0, _pitch(root_hz, mode, c), _n(e * 4.0), 0.3)
		_pluck(s, t0 + _n(e * 4.0), _pitch(root_hz, mode, c + 4), _n(e * 4.0), 0.22)
		if bool(cfg["arp"]):
			for k in 8:
				_pluck(s, t0 + _n(e * float(k)), _pitch(root_hz, mode, c + 7 + int(arp[k])), _n(e * 2.0), 0.1)

	# melodia: motyw A (takty 1-2, 5-6) i odpowiedź B (3-4, 7-8)
	var rhy: Array = [_rhythm(r), _rhythm(r)]
	var con: Array = [_contour(r, 16), _contour(r, 16)]
	for ph in 4:
		var key := ph % 2
		var anchor: int = int(prog[ph * 2]) + 14
		var cur := anchor + 1
		var pos := ph * 16
		var rh: Array = rhy[key]
		var cn: Array = con[key]
		for k in rh.size():
			var d: int = int(rh[k])
			var deg := cur
			if k == rh.size() - 1 and key == 1:
				deg = 18 if ph == 1 else 14
			var f := _pitch(root_hz, mode, deg)
			var t0 := _n(e * float(pos))
			if flute_lead:
				_flute(s, t0, _n(e * float(d) * 0.97), f, 0.34)
			else:
				_pluck(s, t0, f, _n(e * float(mini(d * 2 + 2, 8))), 0.4)
			pos += d
			cur = clampi(cur + int(cn[k % cn.size()]), anchor - 2, anchor + 6)

	# perkusja
	if drums > 0:
		for bar in 8:
			var b0 := bar * 8
			var pat_dum: Array = [0, 4] if drums == 1 else [0, 3, 4]
			var pat_tek: Array = [6] if drums == 1 else [2, 6]
			for p in pat_dum:
				_add_dum(s, _n(e * float(b0 + int(p))), 0.5)
			for p in pat_tek:
				_add_tek(s, _n(e * float(b0 + int(p))), 0.3)
			if drums == 2:
				for k in 8:
					_add_shaker(s, _n(e * float(b0 + k)), 0.07 if k % 2 == 0 else 0.11)

	# echo (zapętlone, więc bez szwu)
	var dry := s.duplicate()
	var d1 := _n(e * 3.0)
	var d2 := _n(e * 5.0)
	for i in total:
		s[i] += dry[posmod(i - d1, total)] * 0.24 + dry[posmod(i - d2, total)] * 0.14

	var peak := 0.0
	for v in s:
		peak = maxf(peak, absf(v))
	if peak > 0.0:
		var k := 0.8 / peak
		for i in s.size():
			s[i] *= k
	return _to_stream(s, true)

func _pluck(s: PackedFloat32Array, start: int, freq: float, dur: int, gain: float) -> void:
	var n := mini(dur, s.size() - start)
	if n <= 0:
		return
	var p := maxi(2, int(float(MIX) / freq))
	var buf := PackedFloat32Array()
	buf.resize(p)
	for i in p:
		buf[i] = _rng.randf_range(-1.0, 1.0)
	for pass_i in 2:  # wygładzenie => miększa, "drewniana" barwa
		for i in p:
			buf[i] = (buf[i] + buf[(i + 1) % p]) * 0.5
	var fade_len := mini(600, n)
	var idx := 0
	for i in n:
		var cur := buf[idx]
		buf[idx] = (cur + buf[(idx + 1) % p]) * 0.5 * 0.9965
		var fade := 1.0 if i < n - fade_len else float(n - i) / float(fade_len)
		s[start + i] += cur * gain * 2.2 * fade
		idx = (idx + 1) % p

func _flute(s: PackedFloat32Array, start: int, dur: int, freq: float, gain: float) -> void:
	var n := mini(dur, s.size() - start)
	if n <= 0:
		return
	var ph := 0.0
	var lp := 0.0
	var atk := maxf(1.0, 0.05 * float(MIX))
	var rel := maxf(1.0, 0.07 * float(MIX))
	for i in n:
		var t := float(i) / float(MIX)
		var vib := 1.0 + 0.008 * sin(t * TAU * 5.2) * minf(1.0, t * 3.0)
		ph += freq * vib / float(MIX)
		lp = lerpf(lp, _rng.randf_range(-1.0, 1.0), 0.15)
		var v := sin(ph * TAU) + 0.22 * sin(ph * TAU * 2.0) + 0.07 * sin(ph * TAU * 3.0) + lp * 0.12
		s[start + i] += v * gain * minf(1.0, float(i) / atk) * minf(1.0, float(n - i) / rel)

func _add_drone(s: PackedFloat32Array, freq: float, gain: float) -> void:
	for i in s.size():
		var ph := freq * float(i) / float(MIX)
		s[i] += (sin(ph * TAU) + 0.35 * sin(ph * TAU * 2.0) + 0.15 * sin(ph * TAU * 3.0)) * gain

func _add_dum(s: PackedFloat32Array, start: int, gain: float) -> void:
	var n := mini(_n(0.22), s.size() - start)
	var ph := 0.0
	var lp := 0.0
	for i in maxi(n, 0):
		var t := float(i) / float(n)
		ph += (105.0 - 45.0 * t) / float(MIX)
		lp = lerpf(lp, _rng.randf_range(-1.0, 1.0), 0.2)
		s[start + i] += (sin(ph * TAU) * 0.9 + lp * 0.25 * (1.0 - t)) * gain * _env(i, n, 0.003, 0.98, 2.2)

func _add_tek(s: PackedFloat32Array, start: int, gain: float) -> void:
	var n := mini(_n(0.1), s.size() - start)
	var ph := 0.0
	var lp := 0.0
	for i in maxi(n, 0):
		var t := float(i) / float(n)
		ph += (210.0 - 60.0 * t) / float(MIX)
		lp = lerpf(lp, _rng.randf_range(-1.0, 1.0), 0.45)
		s[start + i] += (sin(ph * TAU) * 0.5 + lp * 0.4) * gain * _env(i, n, 0.003, 0.98, 2.6)

func _add_shaker(s: PackedFloat32Array, start: int, gain: float) -> void:
	var n := mini(_n(0.06), s.size() - start)
	var prev := 0.0
	for i in maxi(n, 0):
		var raw := _rng.randf_range(-1.0, 1.0)
		s[start + i] += (raw - prev) * 0.5 * gain * _env(i, n, 0.05, 0.95, 2.0)
		prev = raw

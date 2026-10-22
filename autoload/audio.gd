extends Node
## Audio — cała oprawa dźwiękowa generowana proceduralnie (zero plików).
## SFX to krótkie przebiegi zsyntezowane z sinusów, pięt i szumu. Muzyka to
## prosty loop chip-tune składany z akordów, basu i perkusji.

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

# ------------------------------------------------------------------ tablice ---

var _hits := [55.0, 61.0, 66.0, 73.0, 82.0, 92.0, 110.0, 123.0, 146.0, 165.0, 185.0, 220.0]

const THEMES := {
	"menu": {"bpm": 92.0, "roots": [0, 5, 3, 4], "wave": "triangle", "lead": 0.35, "drums": false, "oct": 0},
	"podworko": {"bpm": 128.0, "roots": [0, 0, 5, 7], "wave": "square", "lead": 0.5, "drums": true, "oct": 12},
	"sad": {"bpm": 116.0, "roots": [0, 3, 5, 3], "wave": "triangle", "lead": 0.4, "drums": true, "oct": 12},
	"las": {"bpm": 100.0, "roots": [0, 1, 0, 6], "wave": "sine", "lead": 0.3, "drums": true, "oct": 0},
	"stodola": {"bpm": 134.0, "roots": [0, 0, 6, 5], "wave": "saw", "lead": 0.45, "drums": true, "oct": 0},
	"bagno": {"bpm": 96.0, "roots": [0, 5, 7, 3], "wave": "sine", "lead": 0.32, "drums": true, "oct": 0},
	"gniazdo": {"bpm": 158.0, "roots": [0, 0, 3, 1], "wave": "saw", "lead": 0.58, "drums": true, "oct": 12},
	"boss": {"bpm": 152.0, "roots": [0, 0, 1, 0], "wave": "saw", "lead": 0.55, "drums": true, "oct": 0},
	"victory": {"bpm": 120.0, "roots": [0, 4, 5, 0], "wave": "square", "lead": 0.6, "drums": true, "oct": 12},
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

func stop_music() -> void:
	_current_track = ""
	_music_player.stop()

func set_music_enabled(on: bool) -> void:
	if not on:
		_music_player.stop()
	elif _current_track != "":
		_music_player.play()

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

func _build_music(track: String) -> AudioStreamWAV:
	var cfg: Dictionary = THEMES.get(track, THEMES["menu"])
	var bpm: float = float(cfg["bpm"])
	var step := 60.0 / bpm / 4.0  # szesnastka
	var bars := 4
	var steps := bars * 16
	var total := _n(step * float(steps))
	var s := PackedFloat32Array()
	s.resize(total)
	s.fill(0.0)
	var wave := String(cfg["wave"])
	var roots: Array = cfg["roots"]
	var base_freq: float = _hits[0]
	var lead_gain := float(cfg["lead"])
	var drums := bool(cfg["drums"])
	var oct := int(cfg["oct"])
	var chord := [0, 3, 7, 10]

	for st in steps:
		var bar := st / 16
		var step_in_bar := st % 16
		var root_off: int = int(roots[bar % roots.size()])
		var t0 := int(float(st) * step * float(MIX))
		# --- bas
		if step_in_bar % 4 == 0 or step_in_bar == 14:
			var bf := base_freq * pow(2.0, float(root_off) / 12.0) * 0.5
			_add_note(s, t0, _n(step * 1.6), bf, wave, 0.22 * (1.0 - 0.3 * float(step_in_bar) / 16.0))
		# --- arpeggio / melodia
		if step_in_bar % 2 == 0 or (st % 8) == 7:
			var degree: int = chord[(step_in_bar / 2) % chord.size()]
			if st % 8 == 7:
				degree = chord[(bar * 2 + 1) % chord.size()] + 12
			var lf := base_freq * pow(2.0, float(root_off + degree + oct) / 12.0) * (1.0 if oct > 0 else 2.0)
			_add_note(s, t0, _n(step * 1.1), lf, "pulse" if wave == "square" else wave, lead_gain * 0.4)
		# --- perkusja
		if drums:
			if step_in_bar == 0 or step_in_bar == 8 or (step_in_bar == 11 and bar % 2 == 1):
				_add_kick(s, t0)
			if step_in_bar % 4 == 2:
				_add_hat(s, t0, 0.18)
	# normalizacja
	var peak := 0.0
	for v in s:
		peak = maxf(peak, absf(v))
	if peak > 0.0:
		var k := 0.82 / peak
		for i in s.size():
			s[i] *= k
	return _to_stream(s, true)

func _add_note(s: PackedFloat32Array, start: int, len: int, freq: float, wave: String, gain: float) -> void:
	var n := mini(len, s.size() - start)
	if n <= 0:
		return
	var ph := 0.0
	for i in n:
		ph += freq / float(MIX)
		var t := float(i) / float(n)
		s[start + i] += _osc(wave, ph) * gain * _env(i, n, 0.02, 0.98, 1.2)

func _add_kick(s: PackedFloat32Array, start: int) -> void:
	var n := mini(_n(0.16), s.size() - start)
	var ph := 0.0
	for i in n:
		var t := float(i) / float(n)
		ph += (150.0 * pow(0.25, t)) / float(MIX)
		s[start + i] += _osc("sine", ph) * 0.6 * _env(i, n, 0.002, 0.98, 1.6)

func _add_hat(s: PackedFloat32Array, start: int, gain: float) -> void:
	var n := mini(_n(0.05), s.size() - start)
	var lp := 0.0
	for i in n:
		lp = lerpf(lp, _rng.randf_range(-1.0, 1.0), 0.7)
		s[start + i] += lp * gain * _env(i, n, 0.002, 0.98, 2.5)

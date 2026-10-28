class_name UiPuzzle
extends Control
## Krótkie minigry zamiast walki przy celach fabularnych: "lockpick" (zatrzymaj wskaźnik w zielonym polu
## trzy razy) i "melody" (powtórz melodię z czterech dźwięków). Wynik zgłasza sygnałem `finished`,
## potem wysyła on_close. Esc przerywa bez kary (wynik: porażka).

signal finished(ok: bool)
signal on_close

const KINDS := {
	"lockpick": {"title": "Wyłam zamek", "hint": "Zatrzymaj wskaźnik w zielonym polu — [Spacja] / [E] / przycisk. Trzy kołki; pudło kosztuje życie, ale kołki zostają."},
	"cipher": {"title": "Rozszyfruj kod", "hint": "Ustaw trzy cyfry 1–4 ([1]–[3] zmienia kolejne, albo klik) i sprawdź. Wskazówka: ile cyfr jest na swoim miejscu. Osiem prób."},
	"lights": {"title": "Zapal latarnie", "hint": "Kliknięcie przełącza pole i jego sąsiadów (góra, dół, lewo, prawo). Zapal wszystkie dziewięć latarni."},
	"pairs": {"title": "Dopasuj fragmenty", "hint": "Odkrywaj po dwie karty i znajdź wszystkie pary. Dwanaście pomyłek kończy próbę."},
	"reflex": {"title": "Szybka ręka", "hint": "Klikaj podświetlone pole, zanim zgaśnie. Trafij co najmniej pięć z dziesięciu."},
	"melody": {"title": "Zagraj melodię", "hint": "Posłuchaj, potem powtórz melodię — klawisze [1]–[4] albo klik. Trzy błędy kończą próbę."},
}
const NOTES := [
	{"name": "Do", "col": Color(0.9, 0.35, 0.3), "freq": 1.0},
	{"name": "Re", "col": Color(0.95, 0.8, 0.3), "freq": 1.125},
	{"name": "Mi", "col": Color(0.4, 0.8, 0.4), "freq": 1.25},
	{"name": "Sol", "col": Color(0.4, 0.6, 0.95), "freq": 1.5},
]
const BAR_W := 640.0

var kind := "lockpick"
var _rng := RandomNumberGenerator.new()
var _done := false
var _info: Label
var _body: Control
var _hint: Label

# lockpick
var _pins := 0
var _lives := 3
var _pos := 0.0
var _dir := 1.0
var _speed := 0.9
var _zone_a := 0.0
var _zone_w := 0.2
var _bar: Control
var _marker: ColorRect
var _zone: ColorRect

# cipher
var _code: Array = []
var _guess: Array = [1, 1, 1]
var _tries := 0
var _log: Label
var _digits: Array = []

# lights
var _lit: Array = []
var _cells: Array = []
var _moves := 0

# pairs
var _cards: Array = []
var _faces: Array = []
var _open: Array = []
var _matched := 0
var _misses := 0
var _lock := false

# reflex
var _hits := 0
var _shots := 0
var _target := -1
var _target_id := 0

# melody
var _seq: Array = []
var _step := 0
var _playing := false
var _mistakes := 0
var _btns: Array = []

var _zone_mul := 1.0
var _speed_mul := 1.0

## opts (wytrych): zone / speed (mnożniki) i lives.
func setup(p_kind: String, seed_value: int = 0, opts: Dictionary = {}) -> void:
	_zone_mul = float(opts.get("zone", 1.0))
	_speed_mul = float(opts.get("speed", 1.0))
	_lives = int(opts.get("lives", 3))
	kind = p_kind if KINDS.has(p_kind) else "lockpick"
	_rng.seed = seed_value if seed_value != 0 else int(Time.get_ticks_usec())

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiKit.full(self)
	add_child(UiKit.dim(Color(0.0, 0.0, 0.02, 0.82)))
	var panel := UiKit.panel(Color(0.06, 0.07, 0.11, 0.98), 12)
	panel.position = Vector2(250, 150)
	panel.custom_minimum_size = Vector2(780, 400)
	add_child(panel)
	var v := UiKit.vbox(14)
	panel.add_child(v)
	v.add_child(UiKit.title(String(KINDS[kind]["title"]), 34))
	_info = UiKit.label("", 22, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_info)
	_body = Control.new()
	_body.custom_minimum_size = Vector2(740, 190)
	v.add_child(_body)
	_hint = UiKit.label(String(KINDS[kind]["hint"]), 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.custom_minimum_size = Vector2(740, 0)
	v.add_child(_hint)
	var skip := UiKit.button("Anuluj", 20)
	skip.pressed.connect(func(): _end(false))
	v.add_child(skip)
	if kind == "melody":
		_build_melody()
		_start_melody()
	elif kind == "cipher":
		_build_cipher()
	elif kind == "lights":
		_build_lights()
	elif kind == "pairs":
		_build_pairs()
	elif kind == "reflex":
		_build_reflex()
	else:
		_build_lockpick()
		_next_pin()

func _process(delta: float) -> void:
	if kind != "lockpick" or _done:
		return
	_pos += _dir * _speed * delta
	if _pos > 1.0:
		_pos = 1.0
		_dir = -1.0
	elif _pos < 0.0:
		_pos = 0.0
		_dir = 1.0
	_marker.position.x = _pos * (BAR_W - 10.0)

func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_end(false)
	elif kind == "lockpick" and (event.is_action_pressed("equipment") or event.is_action_pressed("ui_accept")):
		get_viewport().set_input_as_handled()
		_pick()
	elif kind == "cipher" and event is InputEventKey and event.pressed and not event.echo:
		var j: int = int(event.keycode) - KEY_1
		if j >= 0 and j < 3:
			get_viewport().set_input_as_handled()
			_bump(j)
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			get_viewport().set_input_as_handled()
			_check()
	elif kind == "melody" and event is InputEventKey and event.pressed and not event.echo:
		var i: int = int(event.keycode) - KEY_1
		if i >= 0 and i < 4:
			get_viewport().set_input_as_handled()
			_press(i)

func _end(ok: bool) -> void:
	if _done:
		return
	_done = true
	Audio.play("confirm" if ok else "back", 1.0, -2.0)
	finished.emit(ok)
	await get_tree().create_timer(0.9 if ok else 0.0).timeout
	on_close.emit()

# --------------------------------------------------------------- wytrych ---

func _build_lockpick() -> void:
	_bar = Control.new()
	_bar.position = Vector2(50, 50)
	_bar.size = Vector2(BAR_W, 40)
	_body.add_child(_bar)
	var back := ColorRect.new()
	back.color = Color(0.15, 0.14, 0.2)
	back.size = Vector2(BAR_W, 40)
	_bar.add_child(back)
	_zone = ColorRect.new()
	_zone.color = Color(0.3, 0.8, 0.4)
	_zone.size = Vector2(100, 40)
	_bar.add_child(_zone)
	_marker = ColorRect.new()
	_marker.color = Color(1.0, 0.95, 0.7)
	_marker.size = Vector2(10, 52)
	_marker.position.y = -6
	_bar.add_child(_marker)
	var b := UiKit.button("Dociśnij", 26)
	b.position = Vector2(270, 120)
	b.custom_minimum_size = Vector2(200, 56)
	b.pressed.connect(_pick)
	_body.add_child(b)

func _next_pin() -> void:
	_zone_w = clampf((0.32 - 0.04 * _pins) * _zone_mul, 0.08, 0.7)
	_zone_a = _rng.randf_range(0.05, 0.95 - _zone_w)
	_speed = (0.6 + 0.15 * _pins) * _speed_mul
	_zone.position.x = _zone_a * (BAR_W - 10.0)
	_zone.size.x = _zone_w * (BAR_W - 10.0)
	_refresh_info()

func _refresh_info() -> void:
	if kind == "lockpick":
		_info.text = "Kołek %d / 3   ·   Życia: %s" % [_pins + 1, "♥".repeat(_lives)]
	elif kind == "cipher":
		_info.text = "Próba %d / 8" % mini(_tries + 1, 8)
	elif kind == "lights":
		_info.text = "Ruchy: %d" % _moves
	elif kind == "pairs":
		_info.text = "Pary: %d / 6   ·   Pomyłki: %d / 12" % [_matched, _misses]
	elif kind == "reflex":
		_info.text = "Trafienia: %d / 5   ·   Strzał %d / 10" % [_hits, mini(_shots + 1, 10)]
	else:
		_info.text = "Dźwięk %d / %d   ·   Błędy: %d / 3" % [mini(_step + 1, _seq.size()), _seq.size(), _mistakes]

func _pick() -> void:
	if _done:
		return
	var c := _pos
	if c >= _zone_a and c <= _zone_a + _zone_w:
		_pins += 1
		Audio.play("select", 1.2 + 0.1 * _pins, -2.0)
		if _pins >= 3:
			_info.text = "Zamek puścił!"
			_end(true)
			return
		_next_pin()
	else:
		_lives -= 1
		Audio.play("hit", 0.8, -4.0)
		if _lives <= 0:
			_info.text = "Wytrych się złamał."
			_end(false)
			return
		_next_pin()

# --------------------------------------------------------------- melodia ---

func _build_melody() -> void:
	for i in 4:
		var n: Dictionary = NOTES[i]
		var b := Button.new()
		b.text = "%d\n%s" % [i + 1, String(n["name"])]
		b.position = Vector2(20 + i * 180, 40)
		b.custom_minimum_size = Vector2(160, 120)
		b.add_theme_font_size_override("font_size", 26)
		var sb := StyleBoxFlat.new()
		sb.bg_color = (n["col"] as Color).darkened(0.45)
		sb.set_corner_radius_all(10)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_color_override("font_color", UiKit.TEXT)
		b.pressed.connect(func(): _press(i))
		_body.add_child(b)
		_btns.append(b)

func _flash(i: int, on: bool) -> void:
	var sb := StyleBoxFlat.new()
	var col: Color = NOTES[i]["col"]
	sb.bg_color = col if on else col.darkened(0.45)
	sb.set_corner_radius_all(10)
	(_btns[i] as Button).add_theme_stylebox_override("normal", sb)
	if on:
		Audio.play("select", float(NOTES[i]["freq"]), -3.0)

func _start_melody() -> void:
	_seq.clear()
	for i in 3:
		_seq.append(_rng.randi_range(0, 3))
	_play_seq()

func _play_seq() -> void:
	_playing = true
	_step = 0
	_info.text = "Słuchaj…"
	await get_tree().create_timer(0.7).timeout
	for n in _seq:
		if _done or not is_inside_tree():
			return
		_flash(int(n), true)
		await get_tree().create_timer(0.45).timeout
		_flash(int(n), false)
		await get_tree().create_timer(0.2).timeout
	_playing = false
	_refresh_info()

func _press(i: int) -> void:
	if _done or _playing:
		return
	_flash(i, true)
	get_tree().create_timer(0.2).timeout.connect(func(): _flash(i, false))
	if i == int(_seq[_step]):
		_step += 1
		if _step >= _seq.size():
			_info.text = "Piękna melodia!"
			_end(true)
			return
		_refresh_info()
	else:
		_mistakes += 1
		if _mistakes >= 3:
			_info.text = "Fałsz! Spróbuj później."
			_end(false)
			return
		_info.text = "Fałsz! Posłuchaj jeszcze raz…"
		_play_seq()

# ----------------------------------------------------------------- szyfr ---

func _build_cipher() -> void:
	for i in 3:
		_code.append(_rng.randi_range(1, 4))
		var b := Button.new()
		b.position = Vector2(150 + i * 150, 10)
		b.custom_minimum_size = Vector2(120, 90)
		b.add_theme_font_size_override("font_size", 44)
		b.text = "1"
		b.pressed.connect(func(): _bump(i))
		_body.add_child(b)
		_digits.append(b)
	var ok := UiKit.button("Sprawdź", 24)
	ok.position = Vector2(590, 30)
	ok.custom_minimum_size = Vector2(130, 56)
	ok.pressed.connect(_check)
	_body.add_child(ok)
	_log = UiKit.label("", 18, UiKit.TEXT)
	_log.position = Vector2(150, 110)
	_log.custom_minimum_size = Vector2(500, 70)
	_body.add_child(_log)
	_refresh_info()

func _bump(i: int) -> void:
	if _done:
		return
	_guess[i] = int(_guess[i]) % 4 + 1
	(_digits[i] as Button).text = str(_guess[i])
	Audio.play("select", 1.0 + 0.1 * float(_guess[i]), -6.0)

func _check() -> void:
	if _done:
		return
	var hits := 0
	for i in 3:
		if int(_guess[i]) == int(_code[i]):
			hits += 1
	_tries += 1
	if hits == 3:
		_info.text = "Kod złamany!"
		_end(true)
		return
	_log.text = "%s — na miejscu: %d / 3
%s" % [" ".join(_guess.map(func(g): return str(g))), hits, _log.text.get_slice("
", 0)]
	if _tries >= 8:
		_info.text = "Pismo się rozmyło."
		_end(false)
		return
	_refresh_info()

# ------------------------------------------------------------- latarnie ---

func _build_lights() -> void:
	_lit.clear()
	for i in 9:
		_lit.append(true)
	# plansza powstaje z kilku ruchów od rozwiązania, więc da się ją odkręcić w trzech
	var cells: Array = [0, 1, 2, 3, 4, 5, 6, 7, 8]
	for k in 3:
		var c: int = cells.pop_at(_rng.randi_range(0, cells.size() - 1))
		_toggle_area(c)
	if _all_lit():
		_toggle_area(4)
		_toggle_area(0)
	for i in 9:
		var b := Button.new()
		b.position = Vector2(290 + (i % 3) * 66, 8 + (i / 3) * 58)
		b.custom_minimum_size = Vector2(60, 52)
		b.pressed.connect(func(): _light_press(i))
		_body.add_child(b)
		_cells.append(b)
	_paint_lights()
	_refresh_info()

func _toggle_area(i: int) -> void:
	var x := i % 3
	var y := i / 3
	for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var nx: int = x + d.x
		var ny: int = y + d.y
		if nx >= 0 and nx < 3 and ny >= 0 and ny < 3:
			_lit[ny * 3 + nx] = not _lit[ny * 3 + nx]

func _all_lit() -> bool:
	return not _lit.has(false)

func _paint_lights() -> void:
	for i in 9:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1.0, 0.85, 0.35) if _lit[i] else Color(0.14, 0.13, 0.2)
		sb.set_corner_radius_all(8)
		(_cells[i] as Button).add_theme_stylebox_override("normal", sb)
		(_cells[i] as Button).add_theme_stylebox_override("hover", sb)
		(_cells[i] as Button).add_theme_stylebox_override("pressed", sb)

func _light_press(i: int) -> void:
	if _done:
		return
	_toggle_area(i)
	_moves += 1
	Audio.play("select", 1.0 + 0.05 * float(i), -6.0)
	_paint_lights()
	_refresh_info()
	if _all_lit():
		_info.text = "Wszystkie latarnie płoną!"
		_end(true)

# ---------------------------------------------------------------- pary ---

func _build_pairs() -> void:
	var ids: Array = []
	for i in 6:
		ids.append(i)
		ids.append(i)
	for i in range(ids.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var t = ids[i]
		ids[i] = ids[j]
		ids[j] = t
	_faces = ids
	var cols := [Color(0.9, 0.35, 0.3), Color(0.95, 0.8, 0.3), Color(0.4, 0.8, 0.4), Color(0.4, 0.6, 0.95), Color(0.75, 0.5, 0.9), Color(0.95, 0.6, 0.35)]
	var marks := ["♠", "♥", "♣", "♦", "★", "☾"]
	for i in 12:
		var b := Button.new()
		b.position = Vector2(100 + (i % 6) * 90, 14 + (i / 6) * 84)
		b.custom_minimum_size = Vector2(80, 74)
		b.add_theme_font_size_override("font_size", 36)
		b.pressed.connect(func(): _flip(i, cols, marks))
		_body.add_child(b)
		_cards.append(b)
		_paint_card(i, false, cols, marks)
	_refresh_info()

func _paint_card(i: int, up: bool, cols: Array, marks: Array) -> void:
	var b: Button = _cards[i]
	var sb := StyleBoxFlat.new()
	sb.bg_color = (cols[_faces[i]] as Color) if up else Color(0.2, 0.19, 0.3)
	sb.set_corner_radius_all(8)
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, sb)
	b.text = String(marks[_faces[i]]) if up else "?"

func _flip(i: int, cols: Array, marks: Array) -> void:
	if _done or _lock or i in _open or (_cards[i] as Button).disabled:
		return
	_paint_card(i, true, cols, marks)
	_open.append(i)
	Audio.play("select", 1.1, -6.0)
	if _open.size() < 2:
		return
	var a: int = _open[0]
	var c: int = _open[1]
	_open.clear()
	if _faces[a] == _faces[c]:
		_matched += 1
		(_cards[a] as Button).disabled = true
		(_cards[c] as Button).disabled = true
		_refresh_info()
		if _matched >= 6:
			_info.text = "Wszystkie pary!"
			_end(true)
		return
	_misses += 1
	_refresh_info()
	_lock = true
	await get_tree().create_timer(0.7).timeout
	if _done or not is_inside_tree():
		return
	_paint_card(a, false, cols, marks)
	_paint_card(c, false, cols, marks)
	_lock = false
	if _misses >= 12:
		_info.text = "Za dużo pomyłek."
		_end(false)

# ------------------------------------------------------------ szybka ręka ---

func _build_reflex() -> void:
	for i in 9:
		var b := Button.new()
		b.position = Vector2(290 + (i % 3) * 66, 8 + (i / 3) * 58)
		b.custom_minimum_size = Vector2(60, 52)
		b.pressed.connect(func(): _reflex_press(i))
		_body.add_child(b)
		_cells.append(b)
	_paint_reflex()
	_refresh_info()
	_next_target()

func _paint_reflex() -> void:
	for i in 9:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.4, 0.95, 0.55) if i == _target else Color(0.14, 0.13, 0.2)
		sb.set_corner_radius_all(8)
		(_cells[i] as Button).add_theme_stylebox_override("normal", sb)
		(_cells[i] as Button).add_theme_stylebox_override("hover", sb)
		(_cells[i] as Button).add_theme_stylebox_override("pressed", sb)

func _next_target() -> void:
	if _done:
		return
	if _shots >= 10:
		_target = -1
		_paint_reflex()
		var ok := _hits >= 5
		_info.text = ("Szybka ręka! %d / 10" if ok else "Za wolno. %d / 10") % _hits
		_end(ok)
		return
	_target = _rng.randi_range(0, 8)
	_target_id += 1
	var mine := _target_id
	_paint_reflex()
	_refresh_info()
	await get_tree().create_timer(1.7).timeout
	if _done or not is_inside_tree() or mine != _target_id:
		return
	_shots += 1       # zgasło bez kliknięcia
	_next_target()

func _reflex_press(i: int) -> void:
	if _done or _target < 0:
		return
	if i == _target:
		_hits += 1
		Audio.play("select", 1.4, -3.0)
	else:
		Audio.play("hit", 0.8, -6.0)
	_shots += 1
	_target_id += 1      # unieważnia zegar bieżącego pola
	_next_target()

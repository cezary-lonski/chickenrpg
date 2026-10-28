extends CanvasLayer
## Touch — sterowanie dotykowe na telefonie/tablecie (Android): wirtualny joystick, przyciski ataku i akcji, dotykane jajka
## umiejętności. Pojawia się tylko w grze (kampania, etapy, serwer online), a na desktopie po fladze `--touch`.
## Wielodotyk: każdy palec śledzony osobno przez `_input`; akcje trafiają do Input jak z klawiatury.

const JOY_CENTER := Vector2(170, 560)
const JOY_RADIUS := 110.0
const FAN_X0 := 334.0          # pozycja rzędu jajek (jak w UiSkillFan: 640 - 612/2)
const FAN_Y0 := 598.0
const FAN_STEP := 70.0

var enabled := false
var _joy_index := -1
var _joy_vec := Vector2.ZERO
var _btns: Array = []
var _held: Dictionary = {}      # indeks palca -> przycisk
var _canvas: Control
# zawsze dostępny przycisk wyjścia z okien (telefon nie ma klawisza Esc)
var _close_btn := {"id": "close", "pos": Vector2(1236, 44), "r": 30.0, "label": "✕", "kind": "key", "arg": KEY_ESCAPE, "hold": false}

func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	enabled = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available() or "--touch" in OS.get_cmdline_args() or "--touch" in OS.get_cmdline_user_args()
	if ServerMode.is_active():
		enabled = false
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_controls)
	add_child(_canvas)
	# przyciski: kind "act" = akcja Input, "key" = zdarzenie klawisza (okna serwera czytają klawisze)
	_btns = [
		{"id": "light", "pos": Vector2(1160, 590), "r": 58.0, "label": "CIOS", "kind": "act", "arg": "light_attack", "hold": false},
		{"id": "heavy", "pos": Vector2(1040, 640), "r": 44.0, "label": "MOCNY", "kind": "act", "arg": "heavy_attack", "hold": false},
		{"id": "jump", "pos": Vector2(960, 590), "r": 44.0, "label": "SKOK", "kind": "act", "arg": "jump", "hold": true},
		{"id": "dash", "pos": Vector2(1160, 470), "r": 44.0, "label": "UNIK", "kind": "act", "arg": "dash", "hold": false},
		{"id": "block", "pos": Vector2(1050, 520), "r": 40.0, "label": "BLOK", "kind": "act", "arg": "block", "hold": true},
		{"id": "special", "pos": Vector2(1230, 520), "r": 34.0, "label": "FURIA", "kind": "act", "arg": "special", "hold": false},
		{"id": "sprint", "pos": Vector2(60, 440), "r": 34.0, "label": "BIEG", "kind": "act", "arg": "sprint", "hold": true},
		{"id": "talk", "pos": Vector2(1230, 410), "r": 36.0, "label": "E", "kind": "key", "arg": KEY_E, "hold": false},
		{"id": "chat", "pos": Vector2(262, 40), "r": 28.0, "label": "T", "kind": "key", "arg": KEY_T, "hold": false, "mmo": true},
		{"id": "inv", "pos": Vector2(326, 40), "r": 28.0, "label": "I", "kind": "key", "arg": KEY_I, "hold": false, "mmo": true},
		{"id": "pets", "pos": Vector2(390, 40), "r": 28.0, "label": "P", "kind": "key", "arg": KEY_P, "hold": false, "mmo": true},
		{"id": "skills", "pos": Vector2(454, 40), "r": 28.0, "label": "SKILE", "kind": "key", "arg": KEY_O, "hold": false, "mmo": true},
		{"id": "menu", "pos": Vector2(1236, 44), "r": 28.0, "label": "☰", "kind": "key", "arg": KEY_ESCAPE, "hold": false},
	]

func _in_game() -> bool:
	return enabled and Flow.current_screen in ["game", "mmo"]

func _mmo() -> bool:
	return Flow.current_screen == "mmo"

## Czy jakieś okno (ekwipunek, sklep, dialog, pauza…) przejmuje dotyk — wtedy chowamy sterowanie.
func _blocked() -> bool:
	if Flow.overlay != null and is_instance_valid(Flow.overlay):
		return true
	if _mmo():
		for n in get_tree().current_scene.get_children():
			if n is MmoWorld and (n as MmoWorld).hud != null:
				return (n as MmoWorld).hud.is_blocking()
	return false

func _process(_delta: float) -> void:
	_canvas.visible = _in_game()
	if _canvas.visible:
		_canvas.queue_redraw()
		if _blocked() and (_joy_index != -1 or _held.size() > 0 and not _held.values().has(_close_btn)):
			_release_all()
	elif _joy_index != -1 or not _held.is_empty():
		_release_all()

func _release_all() -> void:
	_joy_index = -1
	_set_move(Vector2.ZERO)
	for idx in _held.keys():
		_btn_up(_held[idx])
	_held.clear()

# ---------------------------------------------------------------- rysunek ---

func _draw_controls() -> void:
	var f := ThemeDB.fallback_font
	if _blocked():
		# okno otwarte: tylko przycisk ✕ (odpowiednik Esc)
		_canvas.draw_circle(_close_btn["pos"], _close_btn["r"], Color(0.9, 0.3, 0.3, 0.45))
		_canvas.draw_arc(_close_btn["pos"], _close_btn["r"], 0.0, TAU, 32, Color(1, 1, 1, 0.7), 2.5, true)
		var cw := f.get_string_size("✕", HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		_canvas.draw_string(f, _close_btn["pos"] + Vector2(-cw * 0.5, 9), "✕", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 1, 1, 0.95))
		return
	# joystick
	_canvas.draw_circle(JOY_CENTER, JOY_RADIUS, Color(1, 1, 1, 0.10))
	_canvas.draw_arc(JOY_CENTER, JOY_RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 3.0, true)
	_canvas.draw_circle(JOY_CENTER + _joy_vec * JOY_RADIUS * 0.7, 44.0, Color(1, 1, 1, 0.38 if _joy_index != -1 else 0.22))
	for b in _btns:
		if bool(b.get("mmo", false)) and not _mmo():
			continue
		var held := false
		for idx in _held:
			if _held[idx] == b:
				held = true
		var col := Color(1.0, 0.85, 0.4, 0.5 if held else 0.22)
		_canvas.draw_circle(b["pos"], b["r"], col)
		_canvas.draw_arc(b["pos"], b["r"], 0.0, TAU, 32, Color(1, 1, 1, 0.45), 2.5, true)
		var size := 16 if float(b["r"]) < 40.0 else 18
		var w := f.get_string_size(String(b["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		_canvas.draw_string(f, b["pos"] + Vector2(-w * 0.5, size * 0.35), String(b["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(1, 1, 1, 0.9))

# ----------------------------------------------------------------- wejście ---

func _input(event: InputEvent) -> void:
	if not _in_game():
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			if _touch_down(t.index, t.position):
				get_viewport().set_input_as_handled()
		else:
			if _joy_index == t.index:
				_joy_index = -1
				_set_move(Vector2.ZERO)
			if _held.has(t.index):
				_btn_up(_held[t.index])
				_held.erase(t.index)
	elif event is InputEventScreenDrag and not _blocked():
		var d := event as InputEventScreenDrag
		if d.index == _joy_index:
			_update_joy(d.position)

func _touch_down(index: int, pos: Vector2) -> bool:
	if _blocked():
		if pos.distance_to(_close_btn["pos"]) <= float(_close_btn["r"]) + 14.0:
			_held[index] = _close_btn
			_btn_down(_close_btn)
			return true
		return false
	# przyciski
	for b in _btns:
		if bool(b.get("mmo", false)) and not _mmo():
			continue
		if pos.distance_to(b["pos"]) <= float(b["r"]) + 10.0:
			_held[index] = b
			_btn_down(b)
			return true
	# jajka umiejętności
	if pos.y >= FAN_Y0 and pos.y <= FAN_Y0 + 104.0 and pos.x >= FAN_X0 - 10.0 and pos.x <= FAN_X0 + FAN_STEP * 8.0 + 62.0:
		var i := clampi(int(round((pos.x - FAN_X0 - 26.0) / FAN_STEP)), 0, 8)
		_tap_action("skill_%d" % (i + 1))
		return true
	# joystick: lewa dolna część ekranu
	if pos.x < 480.0 and pos.y > 250.0 and _joy_index == -1:
		_joy_index = index
		_update_joy(pos)
		return true
	return false

func _update_joy(pos: Vector2) -> void:
	var d := pos - JOY_CENTER
	var v := d / JOY_RADIUS
	if v.length() > 1.0:
		v = v.normalized()
	_joy_vec = v
	_set_move(v if v.length() > 0.18 else Vector2.ZERO)

func _set_move(v: Vector2) -> void:
	_joy_vec = v if v != Vector2.ZERO else Vector2.ZERO
	_axis("move_left", maxf(0.0, -v.x))
	_axis("move_right", maxf(0.0, v.x))
	_axis("move_up", maxf(0.0, -v.y))
	_axis("move_down", maxf(0.0, v.y))

func _axis(action: String, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)

func _btn_down(b: Dictionary) -> void:
	if String(b["kind"]) == "act":
		if bool(b["hold"]):
			Input.action_press(String(b["arg"]))
		else:
			_tap_action(String(b["arg"]))
	else:
		_key_event(int(b["arg"]), true)

func _btn_up(b: Dictionary) -> void:
	if String(b["kind"]) == "act":
		if bool(b["hold"]):
			Input.action_release(String(b["arg"]))
	else:
		_key_event(int(b["arg"]), false)

## Krótkie wciśnięcie akcji: Input.parse_input_event trafia też do _unhandled_input.
func _tap_action(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().create_timer(0.08).timeout
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)

func _key_event(code: int, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code as Key
	ev.physical_keycode = code as Key
	ev.pressed = pressed
	Input.parse_input_event(ev)

class_name UiPaintEditor
extends Control
## Tryb Paint: malowanie emblematu (piksele), kolory części oraz edytor animacji
## części ciała (klatki, obroty, przesunięcia, odtwarzanie, zapis).

signal on_close

var back_to := "menu"
var then_screen := "menu"

const PALETTE := [
	"#f9f5e6", "#c9a66b", "#8a5a2b", "#202028", "#b02f2f", "#e8572b",
	"#f4a62a", "#e8d23a", "#7cc24a", "#2f8f4e", "#3fb5b0", "#3a6ea5",
	"#2c3e8f", "#7a4fc2", "#c254b3", "#ffffff", "#808890", "#101014",
]

# ------------------------------------------------------------ płótno pikseli ---

class EmblemCanvas extends Control:
	signal stroke_started
	signal picked(hex: String)
	var n := 12
	var cells: Array = []
	var color := "#e8b923"
	var tool := "pen"
	var _down := false

	func _init() -> void:
		custom_minimum_size = Vector2(336, 336)

	func set_cells(c: Array) -> void:
		cells = c
		queue_redraw()

	func _cell_at(p: Vector2) -> int:
		var cs := size.x / float(n)
		var x := int(p.x / cs)
		var y := int(p.y / cs)
		if x < 0 or y < 0 or x >= n or y >= n:
			return -1
		return y * n + x

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			_down = event.pressed
			if _down:
				stroke_started.emit()
				_apply(event.position)
		elif event is InputEventMouseMotion and _down:
			_apply(event.position)

	func _apply(p: Vector2) -> void:
		var i := _cell_at(p)
		if i < 0:
			return
		match tool:
			"pen":
				cells[i] = color
			"eraser":
				cells[i] = ""
			"picker":
				if String(cells[i]) != "":
					color = String(cells[i])
					picked.emit(color)
			"fill":
				_flood(i, String(cells[i]), color)
		queue_redraw()

	func _flood(start: int, from: String, to: String) -> void:
		if from == to:
			return
		var stack := [start]
		while not stack.is_empty():
			var i: int = stack.pop_back()
			if String(cells[i]) != from:
				continue
			cells[i] = to
			var x := i % n
			var y := i / n
			if x > 0: stack.append(i - 1)
			if x < n - 1: stack.append(i + 1)
			if y > 0: stack.append(i - n)
			if y < n - 1: stack.append(i + n)

	func _draw() -> void:
		var cs := size.x / float(n)
		for y in n:
			for x in n:
				var r := Rect2(Vector2(x, y) * cs, Vector2(cs, cs))
				draw_rect(r, Color(0.22, 0.24, 0.3) if (x + y) % 2 == 0 else Color(0.17, 0.19, 0.25))
				var c := String(cells[y * n + x]) if cells.size() > y * n + x else ""
				if c != "":
					draw_rect(r, Color.html(c))
		for i in n + 1:
			draw_line(Vector2(i * cs, 0), Vector2(i * cs, size.y), Color(0, 0, 0, 0.35), 1.0)
			draw_line(Vector2(0, i * cs), Vector2(size.x, i * cs), Color(0, 0, 0, 0.35), 1.0)

# ------------------------------------------------------------------- stan ---

var _app: Dictionary = {}
var _visual: CreatureVisual
var _tab := "anim"
var _box: VBoxContainer
var _status: Label
var _canvas: EmblemCanvas
var _emblem_undo: Array = []

var _anim_name := "idle"
var _anim: Dictionary = {}
var _frame := 0
var _part := "head"
var _playing := false
var _sliders: Dictionary = {}
var _frame_label: Label

func setup(args: Dictionary) -> void:
	back_to = String(args.get("back", "menu"))
	then_screen = String(args.get("then", "menu"))

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_app = GameState.appearance()
	var n := CosmeticDB.EMBLEM_SIZE
	var em: Array = _app.get("emblem", [])
	if em.size() != n * n:
		em = []
		for i in n * n:
			em.append("")
		_app["emblem"] = em
	UiKit.full(self)
	add_child(UiKit.bg_texture(Color(0.06, 0.07, 0.11)))
	var root := UiKit.vbox(8)
	UiKit.full(root)
	root.offset_left = 24.0
	root.offset_right = -24.0
	root.offset_top = 12.0
	root.offset_bottom = -12.0
	add_child(root)
	root.add_child(UiKit.title("KREATOR ANIMACJI", 40))
	var body := UiKit.hbox(14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	var left := UiKit.panel(UiKit.BG, 12)
	left.custom_minimum_size = Vector2(320, 0)
	body.add_child(left)
	var lv := UiKit.vbox(6)
	left.add_child(lv)
	lv.add_child(UiKit.label("PODGLĄD", 15, UiKit.DIM))
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(290, 300)
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(holder)
	_visual = CreatureVisual.new()
	_visual.position = Vector2(140, 260)
	_visual.body_scale = 2.7
	holder.add_child(_visual)
	var flip := UiKit.button("Obróć postać", 15, UiKit.ACCENT2)
	flip.pressed.connect(func(): _visual.set_facing(-_visual.facing); Audio.play("select"))
	lv.add_child(flip)

	var right := UiKit.panel(UiKit.BG, 12)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	var rv := UiKit.vbox(8)
	right.add_child(rv)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rv.add_child(scroll)
	_box = UiKit.vbox(8)
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_box)

	_status = UiKit.label("", 14, UiKit.GOOD, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(_status)
	var row := UiKit.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(row)
	var back := UiKit.button("Wróć", 20)
	back.pressed.connect(_close)
	row.add_child(back)
	_refresh_preview()
	_switch_tab("anim")

func _process(_delta: float) -> void:
	if _tab == "anim" and _visual:
		_visual.anim_hold = -1.0 if _playing else _frame_time()

func _switch_tab(tab: String) -> void:
	_tab = tab
	Audio.play("select")
	if tab == "anim":
		_load_anim(_anim_name)
	else:
		_visual.set_anim("")
		_visual.anim_hold = -1.0
	_rebuild()

func _rebuild() -> void:
	for c in _box.get_children():
		c.queue_free()
	_sliders.clear()
	match _tab:
		"emblem": _build_emblem()
		"colors": _build_colors()
		"anim": _build_anim()

func _refresh_preview() -> void:
	var id := String(_app.get("look", ""))
	if not CharacterDB.LIST.has(id):
		id = "kurczak"
	_visual.configure(id, CharacterDB.get_data(id)["pal"], 2.7)
	_visual.apply_appearance(_app)
	_visual.set_gear(CosmeticDB.gear_visual(GameState.equipped(), GameState.equipped_meta()) if GameState.has_run() else {})

# -------------------------------------------------------------- emblemat ---

func _build_emblem() -> void:
	_box.add_child(UiKit.label("Maluj emblemat na piersi postaci. Lewy przycisk myszy — rysowanie.", 15, UiKit.DIM))
	var h := UiKit.hbox(14)
	_box.add_child(h)
	_canvas = EmblemCanvas.new()
	_canvas.n = CosmeticDB.EMBLEM_SIZE
	_canvas.set_cells(_app["emblem"])
	_canvas.stroke_started.connect(func():
		_emblem_undo.append((_app["emblem"] as Array).duplicate())
		if _emblem_undo.size() > 60:
			_emblem_undo.pop_front())
	_canvas.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseMotion or e is InputEventMouseButton:
			_refresh_preview())
	h.add_child(_canvas)
	var tools := UiKit.vbox(6)
	h.add_child(tools)
	for entry in [["pen", "Pędzel"], ["eraser", "Gumka"], ["picker", "Pipeta"], ["fill", "Wypełnij"]]:
		var tk := String(entry[0])
		var b := UiKit.button(String(entry[1]) + ("  ●" if _canvas.tool == tk else ""), 16)
		b.custom_minimum_size = Vector2(150, 38)
		b.pressed.connect(func(): _canvas.tool = tk; Audio.play("select"); _rebuild_keep_canvas())
		tools.add_child(b)
	var undo := UiKit.button("Cofnij", 16, UiKit.ACCENT2)
	undo.pressed.connect(func():
		if _emblem_undo.is_empty():
			_status.text = "Nie ma czego cofać."
			return
		_app["emblem"] = _emblem_undo.pop_back()
		_canvas.set_cells(_app["emblem"])
		Audio.play("back")
		_refresh_preview())
	tools.add_child(undo)
	var clear := UiKit.button("Wyczyść", 16, UiKit.BAD)
	clear.pressed.connect(func():
		_emblem_undo.append((_app["emblem"] as Array).duplicate())
		for i in (_app["emblem"] as Array).size():
			_app["emblem"][i] = ""
		_canvas.set_cells(_app["emblem"])
		Audio.play("back")
		_refresh_preview())
	tools.add_child(clear)
	_box.add_child(UiKit.label("Kolor:", 15, UiKit.DIM))
	var grid := GridContainer.new()
	grid.columns = 9
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	_box.add_child(grid)
	for hex in PALETTE:
		var sw := Button.new()
		sw.custom_minimum_size = Vector2(32, 32)
		sw.add_theme_stylebox_override("normal", UiKit.sb(Color.html(String(hex)), 6, 2.0, Color(0, 0, 0, 0.6)))
		sw.add_theme_stylebox_override("hover", UiKit.sb(Color.html(String(hex)).lightened(0.15), 6, 2.0, Color(1, 1, 1, 0.8)))
		sw.add_theme_stylebox_override("pressed", UiKit.sb(Color.html(String(hex)), 6, 2.0, Color(1, 1, 1, 1)))
		var hh: String = hex
		sw.pressed.connect(func(): _canvas.color = hh; _canvas.tool = "pen"; Audio.play("select"))
		grid.add_child(sw)
	var cp := ColorPickerButton.new()
	cp.custom_minimum_size = Vector2(150, 32)
	cp.text = "Własny kolor"
	cp.color = Color.html(_canvas.color)
	cp.edit_alpha = false
	cp.color_changed.connect(func(c: Color): _canvas.color = "#" + c.to_html(false); _canvas.tool = "pen")
	_box.add_child(cp)

func _rebuild_keep_canvas() -> void:
	var keep_tool := _canvas.tool
	var keep_col := _canvas.color
	_rebuild()
	_canvas.tool = keep_tool
	_canvas.color = keep_col

# ---------------------------------------------------------------- kolory ---

func _build_colors() -> void:
	_box.add_child(UiKit.label("Zmień kolor wybranej części (gumka = przywróć domyślny).", 15, UiKit.DIM))
	for key in CosmeticDB.PARTS:
		var pk := String(key)
		var row := UiKit.hbox(8)
		_box.add_child(row)
		var l := UiKit.label(String(CosmeticDB.PARTS[key]), 16, UiKit.TEXT)
		l.custom_minimum_size = Vector2(170, 0)
		row.add_child(l)
		var over: Dictionary = _app.get("colors", {})
		var cur := Color.html(String(over[pk])) if over.has(pk) and String(over[pk]) != "" else Color(_visual.pal.get(pk, Color.WHITE))
		var cp := ColorPickerButton.new()
		cp.custom_minimum_size = Vector2(120, 32)
		cp.color = cur
		cp.edit_alpha = false
		cp.color_changed.connect(func(c: Color):
			if not (_app.get("colors") is Dictionary):
				_app["colors"] = {}
			_app["colors"][pk] = "#" + c.to_html(false)
			_refresh_preview())
		row.add_child(cp)
		var er := UiKit.button("Gumka", 14, UiKit.ACCENT2)
		er.pressed.connect(func():
			(_app["colors"] as Dictionary).erase(pk)
			Audio.play("back")
			_refresh_preview()
			_rebuild())
		row.add_child(er)

# ------------------------------------------------------------- animacje ---

func _load_anim(anim_name: String) -> void:
	_anim_name = anim_name
	var all := GameState.anims()
	_anim = (all.get(anim_name, CosmeticDB.default_anims().get(anim_name, {})) as Dictionary).duplicate(true)
	if (_anim.get("frames", []) as Array).is_empty():
		_anim = {"duration": 1.0, "loop": true, "smooth": true, "frames": [{"t": 0.0, "parts": {}}]}
	_frame = clampi(_frame, 0, (_anim["frames"] as Array).size() - 1)
	_visual.custom_anims = {"__edit": _anim}
	_visual.set_anim("")
	_visual.set_anim("__edit")

func _frame_time() -> float:
	var frames: Array = _anim.get("frames", [])
	if frames.is_empty():
		return 0.0
	return float(frames[clampi(_frame, 0, frames.size() - 1)]["t"])

func _frame_part() -> Array:
	var f: Dictionary = (_anim["frames"] as Array)[_frame]
	var parts: Dictionary = f["parts"]
	if not parts.has(_part):
		parts[_part] = [0.0, 0.0, 0.0]
	return parts[_part]

func _build_anim() -> void:
	_box.add_child(UiKit.label("Animacja jest nakładana na ruch postaci (addytywnie) i odtwarzana w grze.", 14, UiKit.DIM))
	var names := GridContainer.new()
	names.columns = 4
	names.add_theme_constant_override("h_separation", 6)
	names.add_theme_constant_override("v_separation", 6)
	_box.add_child(names)
	for key in CosmeticDB.ANIM_NAMES:
		var ak := String(key)
		var b := UiKit.button(String(CosmeticDB.ANIM_NAMES[key]) + ("  ●" if ak == _anim_name else ""), 14)
		b.pressed.connect(func(): _frame = 0; _load_anim(ak); Audio.play("select"); _rebuild())
		names.add_child(b)
	# część ciała
	_box.add_child(UiKit.label("Zaznaczony element:", 15, UiKit.DIM))
	var parts := UiKit.hbox(6)
	_box.add_child(parts)
	for key in CosmeticDB.ANIM_PARTS:
		var pk := String(key)
		var pb := UiKit.button(String(CosmeticDB.ANIM_PARTS[key]) + ("  ●" if pk == _part else ""), 14)
		pb.pressed.connect(func(): _part = pk; Audio.play("select"); _rebuild())
		parts.add_child(pb)
	# klatki
	var frames: Array = _anim["frames"]
	_frame_label = UiKit.label("Klatka %d / %d  (t = %.2f s)" % [_frame + 1, frames.size(), _frame_time()], 16, UiKit.ACCENT)
	_box.add_child(_frame_label)
	var fr := UiKit.hbox(4)
	_box.add_child(fr)
	for i in frames.size():
		var idx := i
		var fb := UiKit.button(str(i + 1) + ("●" if i == _frame else ""), 14)
		fb.custom_minimum_size = Vector2(44, 32)
		fb.pressed.connect(func(): _frame = idx; _playing = false; Audio.play("select"); _rebuild())
		fr.add_child(fb)
	var fa := UiKit.hbox(6)
	_box.add_child(fa)
	var add := UiKit.button("+ Dodaj klatkę", 15)
	add.pressed.connect(_add_frame)
	fa.add_child(add)
	var dup := UiKit.button("Duplikuj", 15, UiKit.ACCENT2)
	dup.pressed.connect(_dup_frame)
	fa.add_child(dup)
	var del := UiKit.button("Usuń klatkę", 15, UiKit.BAD)
	del.pressed.connect(_del_frame)
	fa.add_child(del)
	# suwaki
	var cur := _frame_part()
	_slider_row("Pozycja X", -24.0, 24.0, 0.5, float(cur[0]), func(v: float): _frame_part()[0] = v)
	_slider_row("Pozycja Y", -24.0, 24.0, 0.5, float(cur[1]), func(v: float): _frame_part()[1] = v)
	_slider_row("Obrót (°)", -180.0, 180.0, 1.0, rad_to_deg(float(cur[2])), func(v: float): _frame_part()[2] = deg_to_rad(v))
	_slider_row("Czas klatki (s)", 0.0, float(_anim.get("duration", 1.0)), 0.01, _frame_time(), func(v: float):
		((_anim["frames"] as Array)[_frame] as Dictionary)["t"] = v
		_anim["frames"].sort_custom(func(a, b): return float(a["t"]) < float(b["t"])))
	_slider_row("Czas trwania (s)", 0.1, 4.0, 0.05, float(_anim.get("duration", 1.0)), func(v: float): _anim["duration"] = v)
	var opts := UiKit.hbox(10)
	_box.add_child(opts)
	var loop := CheckBox.new()
	loop.text = "Zapętlaj"
	loop.button_pressed = bool(_anim.get("loop", true))
	loop.toggled.connect(func(on: bool): _anim["loop"] = on)
	opts.add_child(loop)
	var smooth := CheckBox.new()
	smooth.text = "Płynne przejścia"
	smooth.button_pressed = bool(_anim.get("smooth", true))
	smooth.toggled.connect(func(on: bool): _anim["smooth"] = on)
	opts.add_child(smooth)
	var spd := UiKit.hbox(6)
	_box.add_child(spd)
	spd.add_child(UiKit.label("Szybkość podglądu:", 14, UiKit.DIM))
	for sp in [0.5, 1.0, 2.0]:
		var sv: float = sp
		var sb := UiKit.button("x%.1f" % sv, 13)
		sb.pressed.connect(func(): _visual.anim_speed = sv; Audio.play("select"))
		spd.add_child(sb)
	var pl := UiKit.hbox(8)
	_box.add_child(pl)
	var play := UiKit.button("▶ Odtwarzaj" if not _playing else "■ Zatrzymaj", 17)
	play.pressed.connect(func():
		_playing = not _playing
		if _playing:
			_visual.set_anim("")
			_visual.set_anim("__edit")
		Audio.play("select")
		_rebuild())
	pl.add_child(play)
	var sv2 := UiKit.button("Zapisz animację", 17, UiKit.GOOD)
	sv2.pressed.connect(_save_anim)
	pl.add_child(sv2)
	var rs := UiKit.button("Przywróć domyślną", 15, UiKit.BAD)
	rs.pressed.connect(func():
		GameState.reset_anim(_anim_name)
		_frame = 0
		_load_anim(_anim_name)
		_status.text = "Przywrócono domyślną animację: %s." % String(CosmeticDB.ANIM_NAMES[_anim_name])
		Audio.play("back")
		_rebuild())
	pl.add_child(rs)

func _slider_row(title_text: String, lo: float, hi: float, step: float, value: float, on_change: Callable) -> void:
	var row := UiKit.hbox(8)
	_box.add_child(row)
	var l := UiKit.label(title_text, 14, UiKit.TEXT)
	l.custom_minimum_size = Vector2(130, 0)
	row.add_child(l)
	var sl := HSlider.new()
	sl.min_value = lo
	sl.max_value = maxf(hi, lo + step)
	sl.step = step
	sl.value = clampf(value, lo, maxf(hi, lo + step))
	sl.custom_minimum_size = Vector2(260, 24)
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sl)
	var val := UiKit.label("%.2f" % sl.value, 13, UiKit.DIM)
	val.custom_minimum_size = Vector2(60, 0)
	row.add_child(val)
	sl.value_changed.connect(func(v: float):
		val.text = "%.2f" % v
		on_change.call(v)
		_playing = false)

func _add_frame() -> void:
	var frames: Array = _anim["frames"]
	var dur := float(_anim.get("duration", 1.0))
	var t := minf(dur, _frame_time() + dur / float(frames.size() + 1))
	var src: Dictionary = frames[_frame]
	frames.append({"t": t, "parts": (src["parts"] as Dictionary).duplicate(true)})
	frames.sort_custom(func(a, b): return float(a["t"]) < float(b["t"]))
	_frame = frames.size() - 1
	for i in frames.size():
		if is_equal_approx(float(frames[i]["t"]), t):
			_frame = i
	_playing = false
	Audio.play("confirm")
	_rebuild()

func _dup_frame() -> void:
	_add_frame()

func _del_frame() -> void:
	var frames: Array = _anim["frames"]
	if frames.size() <= 1:
		_status.text = "Animacja musi mieć co najmniej jedną klatkę."
		Audio.play("deny")
		return
	frames.remove_at(_frame)
	_frame = clampi(_frame, 0, frames.size() - 1)
	Audio.play("back")
	_rebuild()

func _save_anim() -> void:
	GameState.save_anim(_anim_name, _anim)
	_status.text = "Zapisano animację: %s." % String(CosmeticDB.ANIM_NAMES[_anim_name])
	Audio.play("confirm")

# ---------------------------------------------------------------- zapis ---

func _save_look() -> void:
	GameState.set_appearance(_app)
	_status.text = "Wygląd zapisany."
	Audio.play("confirm")

func _reload_look() -> void:
	_app = GameState.appearance()
	var n := CosmeticDB.EMBLEM_SIZE
	if (_app["emblem"] as Array).size() != n * n:
		_app["emblem"] = []
		for i in n * n:
			_app["emblem"].append("")
	_emblem_undo.clear()
	_refresh_preview()
	_status.text = "Wczytano zapisany wygląd."
	Audio.play("select")
	_rebuild()

func _close() -> void:
	Audio.play("back")
	on_close.emit()
	if back_to == "creator":
		Flow.goto("creator", {"then": then_screen})
	else:
		Flow.goto("menu")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and event.is_action_pressed("ui_cancel"):
		_close()
